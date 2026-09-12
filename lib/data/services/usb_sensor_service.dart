import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../core/constants/sensor_constants.dart';
import '../models/modbus_parser.dart';
import '../models/soil_reading.dart';

enum UsbConnectionStatus {
  disconnected,
  connecting,
  connected,
  simulating,
  error,
}

class UsbSensorService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _serialSubscription;
  Timer? _pollingTimer;
  Timer? _simulationTimer;

  final List<int> _rxBuffer = [];
  final Random _random = Random();

  final _readingController = StreamController<SoilReading>.broadcast();
  final _statusController = StreamController<UsbConnectionStatus>.broadcast();
  final _telemetryController = StreamController<void>.broadcast();

  Stream<SoilReading> get readingStream => _readingController.stream;
  Stream<UsbConnectionStatus> get statusStream => _statusController.stream;
  Stream<void> get telemetryStream => _telemetryController.stream;

  UsbConnectionStatus _currentStatus = UsbConnectionStatus.disconnected;
  UsbConnectionStatus get currentStatus => _currentStatus;

  int _baudRate = SensorConstants.defaultBaudRate;
  int get baudRate => _baudRate;

  bool _isSimulationMode = false;
  bool get isSimulationMode => _isSimulationMode;

  // Real-time Hardware Diagnostics
  int _txCount = 0;
  int get txCount => _txCount;

  int _rxByteCount = 0;
  int get rxByteCount => _rxByteCount;

  String _lastRxHex = '-';
  String get lastRxHex => _lastRxHex;

  String _lastTxHex = '-';
  String get lastTxHex => _lastTxHex;

  bool _hasReceivedValidReading = false;
  bool get hasReceivedValidReading => _hasReceivedValidReading;

  int _consecutiveEmptyPolls = 0;
  bool _isAutoBaudActive = true;
  bool get isAutoBaudActive => _isAutoBaudActive;

  int _queryCycle = 0;

  // Baseline values for realistic simulated fluctuation
  double _simTemp = 28.6;
  double _simMoist = 54.5;
  int _simEc = 485;
  double _simPh = 6.42;
  int _simN = 128;
  int _simP = 36;
  int _simK = 184;
  int _simFert = 350;

  void _setStatus(UsbConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _notifyTelemetry() {
    if (!_telemetryController.isClosed) {
      _telemetryController.add(null);
    }
  }

  /// Initialize and attempt to connect to physical USB-to-Serial soil probe
  Future<bool> connect({int? baudRate}) async {
    if (baudRate != null) _baudRate = baudRate;
    _setStatus(UsbConnectionStatus.connecting);
    _consecutiveEmptyPolls = 0;

    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        debugPrint('[UsbSensorService] No USB devices found.');
        _setStatus(UsbConnectionStatus.disconnected);
        return false;
      }

      // Pick first compatible device (CH340, CP2102, FTDI, or Prolific)
      final device = devices.first;
      _port = await device.create();
      if (_port == null) {
        _setStatus(UsbConnectionStatus.error);
        return false;
      }

      final opened = await _port!.open();
      if (!opened) {
        _setStatus(UsbConnectionStatus.error);
        return false;
      }

      // Flow control configuration for RS485 half-duplex:
      // DTR = true (assert data terminal ready)
      // RTS = false (Crucial: prevents MAX485 from locking into transmit mode which mutes the receiver)
      await _port!.setDTR(true);
      await _port!.setRTS(false);
      try {
        await _port!.setFlowControl(UsbPort.FLOW_CONTROL_OFF);
      } catch (_) {}

      await _port!.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _rxBuffer.clear();
      _serialSubscription = _port!.inputStream?.listen(_onDataReceived);

      // Start periodic Modbus polling
      _startPolling();
      _setStatus(UsbConnectionStatus.connected);
      _notifyTelemetry();
      return true;
    } catch (e) {
      debugPrint('[UsbSensorService] USB Connection error: $e');
      _setStatus(UsbConnectionStatus.error);
      return false;
    }
  }

  /// Change baud rate dynamically on an active port (e.g. 4800 <-> 9600)
  Future<void> switchBaudRate(int newBaud) async {
    _baudRate = newBaud;
    _consecutiveEmptyPolls = 0;
    if (_port != null && _currentStatus == UsbConnectionStatus.connected) {
      try {
        await _port!.setPortParameters(
          _baudRate,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );
        _rxBuffer.clear();
        debugPrint('[UsbSensorService] Baud rate switched to $_baudRate bps');
      } catch (e) {
        debugPrint('[UsbSensorService] Error switching baud rate: $e');
      }
    }
    _notifyTelemetry();
  }

  void toggleAutoBaud([bool? enable]) {
    _isAutoBaudActive = enable ?? !_isAutoBaudActive;
    _notifyTelemetry();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: SensorConstants.pollingIntervalMs),
      (_) => _sendModbusQuery(),
    );
  }

  Future<void> _sendModbusQuery() async {
    if (_port == null || _currentStatus != UsbConnectionStatus.connected) return;
    try {
      // Alternate or select query:
      // Query 7 registers (Moist, Temp, EC, pH, N, P, K) - Works on BOTH 7-in-1 and 8-in-1 probes
      // If valid reading confirmed, keep optimal register count
      final regCount = (_hasReceivedValidReading || (_queryCycle % 2 == 0)) ? 7 : 8;
      _queryCycle++;

      final query = ModbusParser.buildReadRequest(
        slaveId: SensorConstants.defaultSlaveId,
        startRegister: 0x0000,
        registerCount: regCount,
      );

      _txCount++;
      _lastTxHex = query.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

      await _port!.write(query);
      _notifyTelemetry();

      // Auto-baud detection check
      if (!_hasReceivedValidReading && _isAutoBaudActive) {
        _consecutiveEmptyPolls++;
        // If 4 consecutive queries (~6s) receive 0 responses, automatically switch baud rate (4800 <-> 9600)
        if (_consecutiveEmptyPolls >= 4) {
          _consecutiveEmptyPolls = 0;
          final nextBaud = (_baudRate == 4800) ? 9600 : 4800;
          debugPrint('[UsbSensorService] Auto-Baud scanning: trying $nextBaud bps...');
          await switchBaudRate(nextBaud);
        }
      }
    } catch (e) {
      debugPrint('[UsbSensorService] Error sending query: $e');
    }
  }

  void _onDataReceived(Uint8List data) {
    if (data.isEmpty) return;

    _rxByteCount += data.length;
    _consecutiveEmptyPolls = 0;
    _lastRxHex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    _notifyTelemetry();

    _rxBuffer.addAll(data);

    // If buffer grows too large without valid frame, keep the trailing 32 bytes
    if (_rxBuffer.length > 128) {
      _rxBuffer.removeRange(0, _rxBuffer.length - 32);
    }

    final reading = ModbusParser.parseResponse(
      _rxBuffer,
      expectedSlaveId: SensorConstants.defaultSlaveId,
    );

    if (reading != null) {
      _hasReceivedValidReading = true;
      _readingController.add(reading);
      _rxBuffer.clear();
      _notifyTelemetry();
    }
  }

  /// Start Simulated / Demo Data Stream (for testing without physical hardware)
  void startSimulation() {
    disconnect();
    _isSimulationMode = true;
    _setStatus(UsbConnectionStatus.simulating);

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: SensorConstants.pollingIntervalMs),
      (_) {
        // Natural micro-fluctuations
        _simTemp += (_random.nextDouble() - 0.5) * 0.2;
        _simMoist += (_random.nextDouble() - 0.5) * 0.4;
        _simEc += _random.nextInt(5) - 2;
        _simPh += (_random.nextDouble() - 0.5) * 0.04;
        _simN += _random.nextInt(3) - 1;
        _simP += _random.nextInt(3) - 1;
        _simK += _random.nextInt(3) - 1;

        // Boundaries clamp
        _simTemp = _simTemp.clamp(20.0, 36.0);
        _simMoist = _simMoist.clamp(30.0, 85.0);
        _simEc = _simEc.clamp(200, 1800);
        _simPh = _simPh.clamp(5.0, 8.0);
        _simN = _simN.clamp(50, 300);
        _simP = _simP.clamp(15, 90);
        _simK = _simK.clamp(80, 400);
        _simFert = (_simEc * 0.72).round();

        final simReading = SoilReading(
          temperature: double.parse(_simTemp.toStringAsFixed(1)),
          moisture: double.parse(_simMoist.toStringAsFixed(1)),
          conductivity: _simEc,
          ph: double.parse(_simPh.toStringAsFixed(2)),
          nitrogen: _simN,
          phosphorus: _simP,
          potassium: _simK,
          fertility: _simFert,
          timestamp: DateTime.now(),
        );

        _readingController.add(simReading);
      },
    );
  }

  /// Disconnect USB port and stop timers
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _simulationTimer?.cancel();
    await _serialSubscription?.cancel();
    await _port?.close();
    _port = null;
    _rxBuffer.clear();
    _isSimulationMode = false;
    _hasReceivedValidReading = false;
    _setStatus(UsbConnectionStatus.disconnected);
    _notifyTelemetry();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _simulationTimer?.cancel();
    _serialSubscription?.cancel();
    _port?.close();
    _port = null;
    _rxBuffer.clear();
    _readingController.close();
    _statusController.close();
    _telemetryController.close();
  }
}
