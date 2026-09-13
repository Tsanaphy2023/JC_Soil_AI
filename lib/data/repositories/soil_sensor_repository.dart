import 'dart:async';
import '../models/soil_reading.dart';
import '../services/export_service.dart';
import '../services/usb_sensor_service.dart';

class SoilSensorRepository {
  final UsbSensorService _sensorService;
  final List<SoilReading> _history = [];
  final int maxHistorySize;

  SoilReading _currentReading = SoilReading.initial();
  SoilReading get currentReading => _currentReading;

  List<SoilReading> get history => List.unmodifiable(_history);

  SoilSensorRepository({
    UsbSensorService? sensorService,
    this.maxHistorySize = 1000,
  }) : _sensorService = sensorService ?? UsbSensorService() {
    _sensorService.readingStream.listen((reading) {
      _currentReading = reading;
      _history.add(reading);
      if (_history.length > maxHistorySize) {
        _history.removeAt(0);
      }
    });
  }

  Stream<SoilReading> get readingStream => _sensorService.readingStream;
  Stream<UsbConnectionStatus> get statusStream => _sensorService.statusStream;
  Stream<void> get telemetryStream => _sensorService.telemetryStream;

  UsbConnectionStatus get currentStatus => _sensorService.currentStatus;
  bool get isSimulationMode => _sensorService.isSimulationMode;
  int get baudRate => _sensorService.baudRate;

  int get txCount => _sensorService.txCount;
  int get rxByteCount => _sensorService.rxByteCount;
  String get lastRxHex => _sensorService.lastRxHex;
  String get lastTxHex => _sensorService.lastTxHex;
  bool get hasReceivedValidReading => _sensorService.hasReceivedValidReading;
  bool get isAutoBaudActive => _sensorService.isAutoBaudActive;
  bool get isAutoConnectEnabled => _sensorService.isAutoConnectEnabled;
  int get pollingIntervalMs => _sensorService.pollingIntervalMs;

  Future<bool> connect({int? baudRate}) => _sensorService.connect(baudRate: baudRate);
  Future<bool> autoConnectNow() => _sensorService.autoConnectNow();
  Future<void> switchBaudRate(int baud) => _sensorService.switchBaudRate(baud);
  void toggleAutoBaud([bool? enable]) => _sensorService.toggleAutoBaud(enable);
  void toggleAutoConnect([bool? enable]) => _sensorService.toggleAutoConnect(enable);
  void setPollingInterval(int ms) => _sensorService.setPollingInterval(ms);

  Future<void> disconnect() => _sensorService.disconnect();

  void startSimulation() => _sensorService.startSimulation();

  void clearHistory() {
    _history.clear();
  }

  Future<ExportResult> exportHistory({String filename = 'Soil_parameters.csv'}) {
    return ExportService.exportToSpreadsheet(_history, filename: filename);
  }

  void dispose() {
    _sensorService.dispose();
  }
}
