import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../core/constants/sensor_constants.dart';
import '../../core/utils/crc16.dart';
import '../models/ph_sensor_reading.dart';

enum UsbStatus { disconnected, connecting, connected, error }

/// Physical USB Serial Driver for RS485 Modbus Soil Probes with Hotplug Auto-Connect
class UsbPhService {
  UsbPort? _port;
  UsbStatus _status = UsbStatus.disconnected;
  StreamSubscription<UsbEvent>? _usbEventSub;
  Timer? _pollTimer;
  Timer? _watchdogTimer;
  final List<int> _rxBuffer = [];

  final _readingController = StreamController<SoilPhReading>.broadcast();
  Stream<SoilPhReading> get readingStream => _readingController.stream;

  final _statusController = StreamController<UsbStatus>.broadcast();
  Stream<UsbStatus> get statusStream => _statusController.stream;

  UsbStatus get status => _status;
  int _currentBaudRate = SensorConstants.defaultBaudRate;
  int get currentBaudRate => _currentBaudRate;

  int _txCount = 0;
  int get txCount => _txCount;

  int _rxByteCount = 0;
  int get rxByteCount => _rxByteCount;

  String _lastHexRx = '';
  String get lastHexRx => _lastHexRx;

  String _lastHexTx = '';
  String get lastHexTx => _lastHexTx;

  bool _isConnecting = false;
  int _consecutiveEmptyPolls = 0;
  int _queryCycle = 0;
  bool _hasReceivedValidReading = false;
  bool get hasReceivedValidReading => _hasReceivedValidReading;

  // Supported Commands: 4 registers, 7 registers, 8 registers
  static final Uint8List _cmd4Registers = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x04, 0x44, 0x09]);
  static final Uint8List _cmd7Registers = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x07, 0x04, 0x08]);
  static final Uint8List _cmd8Registers = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x08, 0x44, 0x0C]);

  UsbPhService() {
    _initHotplugListener();
    _startWatchdog();
    // Auto-connect attempt on startup
    Future.microtask(() => autoConnect());
  }

  void _setStatus(UsbStatus s) {
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  /// Listen for USB-C cable plug/unplug events (Hotplug)
  void _initHotplugListener() {
    try {
      _usbEventSub = UsbSerial.usbEventStream?.listen((UsbEvent event) {
        debugPrint('[UsbPhService] USB Event: ${event.event}');
        if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
          debugPrint('[UsbPhService] Soil Probe USB Attached. Attempting auto-connect...');
          autoConnect();
        } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
          debugPrint('[UsbPhService] Soil Probe USB Detached.');
          disconnect();
        }
      });
    } catch (e) {
      debugPrint('[UsbPhService] Hotplug listener error: $e');
    }
  }

  /// Background watchdog that checks for attached Soil Parameter Tester
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_status == UsbStatus.disconnected && !_isConnecting) {
        try {
          final devices = await UsbSerial.listDevices();
          if (devices.isNotEmpty) {
            autoConnect();
          }
        } catch (_) {}
      }
    });
  }

  /// Auto-connect to first available USB Soil Probe
  Future<bool> autoConnect() async {
    if (_isConnecting || _status == UsbStatus.connected) return true;
    _isConnecting = true;
    final success = await connect(baudRate: _currentBaudRate);
    _isConnecting = false;
    return success;
  }

  /// Scan and connect to compatible USB serial device
  Future<bool> connect({int baudRate = SensorConstants.defaultBaudRate}) async {
    _currentBaudRate = baudRate;
    _setStatus(UsbStatus.connecting);

    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        _setStatus(UsbStatus.disconnected);
        return false;
      }

      final device = devices.first;
      debugPrint('[UsbPhService] Connecting to ${device.productName} (VID:${device.vid}, PID:${device.pid}) at $baudRate bps');
      
      _port = await device.create();
      if (_port == null) {
        _setStatus(UsbStatus.error);
        return false;
      }

      final bool openResult = await _port!.open();
      if (!openResult) {
        _setStatus(UsbStatus.error);
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        _currentBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _rxBuffer.clear();
      _consecutiveEmptyPolls = 0;
      _hasReceivedValidReading = false;

      _port!.inputStream?.listen(_onDataReceived, onError: (e) {
        debugPrint('[UsbPhService] USB Stream error: $e');
        _setStatus(UsbStatus.error);
      }, onDone: () {
        debugPrint('[UsbPhService] USB Stream closed.');
        disconnect();
      });

      _startPolling();
      _setStatus(UsbStatus.connected);
      return true;
    } catch (e) {
      debugPrint('[UsbPhService] Connection exception: $e');
      _setStatus(UsbStatus.error);
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: SensorConstants.defaultPollingIntervalMs),
      (_) => _sendPollCommand(),
    );
  }

  void _sendPollCommand() {
    if (_port == null || _status != UsbStatus.connected) return;

    try {
      // Alternate between 4-register and 8-register query if waiting for response
      Uint8List cmd;
      if (_hasReceivedValidReading) {
        cmd = _cmd4Registers;
      } else {
        _queryCycle++;
        if (_queryCycle % 3 == 0) {
          cmd = _cmd4Registers;
        } else if (_queryCycle % 3 == 1) {
          cmd = _cmd7Registers;
        } else {
          cmd = _cmd8Registers;
        }
      }

      _port!.write(cmd);
      _txCount++;
      _lastHexTx = cmd.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

      // Auto-Baud detection: If no data after 10 polls, switch 4800 <-> 9600 bps
      if (!_hasReceivedValidReading) {
        _consecutiveEmptyPolls++;
        if (_consecutiveEmptyPolls >= 10) {
          _consecutiveEmptyPolls = 0;
          _switchBaudRate();
        }
      }
    } catch (_) {}
  }

  Future<void> _switchBaudRate() async {
    final nextBaud = (_currentBaudRate == 4800) ? 9600 : 4800;
    debugPrint('[UsbPhService] Auto-Baud: Switching to $nextBaud bps...');
    _currentBaudRate = nextBaud;
    try {
      await _port?.setPortParameters(
        _currentBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
    } catch (_) {}
  }

  void _onDataReceived(Uint8List data) {
    _rxByteCount += data.length;
    _rxBuffer.addAll(data);
    _consecutiveEmptyPolls = 0;

    // Keep buffer bounded
    if (_rxBuffer.length > 256) {
      _rxBuffer.removeRange(0, _rxBuffer.length - 64);
    }

    // Look for valid Modbus frame: [01] [03] [ByteCount] ... [CRC_L] [CRC_H]
    for (int i = 0; i <= _rxBuffer.length - 9; i++) {
      if (_rxBuffer[i] == 0x01 && _rxBuffer[i + 1] == 0x03) {
        final int byteCount = _rxBuffer[i + 2];
        final int expectedFrameLength = 3 + byteCount + 2;

        if (i + expectedFrameLength <= _rxBuffer.length) {
          final candidate = Uint8List.fromList(
            _rxBuffer.sublist(i, i + expectedFrameLength),
          );

          if (Crc16.checkCrc(candidate)) {
            _lastHexRx = candidate.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
            _hasReceivedValidReading = true;
            final reading = SoilPhReading.fromModbusBytes(candidate);
            _readingController.add(reading);
            _rxBuffer.removeRange(0, i + expectedFrameLength);
            break;
          }
        }
      }
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      await _port?.close();
    } catch (_) {}
    _port = null;
    _setStatus(UsbStatus.disconnected);
  }

  void dispose() {
    _watchdogTimer?.cancel();
    _usbEventSub?.cancel();
    disconnect();
    _readingController.close();
    _statusController.close();
  }
}
