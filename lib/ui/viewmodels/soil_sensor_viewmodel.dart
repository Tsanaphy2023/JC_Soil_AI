import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/soil_reading.dart';
import '../../data/repositories/soil_sensor_repository.dart';
import '../../data/services/export_service.dart';
import '../../data/services/usb_sensor_service.dart';
import '../../domain/models/agronomic_assessment.dart';
import '../../domain/models/deep_learning_calibrator.dart';

class SoilSensorViewModel extends ChangeNotifier {
  final SoilSensorRepository _repository;
  StreamSubscription<SoilReading>? _readingSub;
  StreamSubscription<UsbConnectionStatus>? _statusSub;
  StreamSubscription<void>? _telemetrySub;

  SoilReading _rawReading = SoilReading.initial();
  SoilReading get rawReading => _rawReading;

  bool _isAiCalibrationEnabled = true;
  bool get isAiCalibrationEnabled => _isAiCalibrationEnabled;

  CalibratedSoilResult _calibrationResult = DeepLearningCalibrator.calibrate(SoilReading.initial());
  CalibratedSoilResult get calibrationResult => _calibrationResult;

  SoilReading get displayReading =>
      _isAiCalibrationEnabled ? _calibrationResult.calibratedReading : _rawReading;

  // For backward-compatibility
  SoilReading get latestReading => displayReading;

  AgronomicAssessment _assessment = AgronomicAssessment.evaluate(SoilReading.initial());
  AgronomicAssessment get assessment => _assessment;

  UsbConnectionStatus _status = UsbConnectionStatus.disconnected;
  UsbConnectionStatus get status => _status;

  String? _lastExportPath;
  String? get lastExportPath => _lastExportPath;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  List<SoilReading> get history => _repository.history;
  bool get isSimulationMode => _repository.isSimulationMode;
  int get baudRate => _repository.baudRate;

  // Hardware Diagnostics & Telemetry
  int get txCount => _repository.txCount;
  int get rxByteCount => _repository.rxByteCount;
  String get lastRxHex => _repository.lastRxHex;
  String get lastTxHex => _repository.lastTxHex;
  bool get hasReceivedValidReading => _repository.hasReceivedValidReading;
  bool get isAutoBaudActive => _repository.isAutoBaudActive;
  bool get isAutoConnectEnabled => _repository.isAutoConnectEnabled;
  int get pollingIntervalMs => _repository.pollingIntervalMs;

  SoilSensorViewModel({SoilSensorRepository? repository})
      : _repository = repository ?? SoilSensorRepository() {
    _status = _repository.currentStatus;
    _rawReading = _repository.currentReading;
    _processNewReading(_rawReading);

    _readingSub = _repository.readingStream.listen((reading) {
      _rawReading = reading;
      _processNewReading(reading);
      notifyListeners();
    });

    _statusSub = _repository.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _telemetrySub = _repository.telemetryStream.listen((_) {
      notifyListeners();
    });

    // Auto-connect to USB OTG sensor immediately on app startup
    if (_repository.isAutoConnectEnabled && _status != UsbConnectionStatus.connected) {
      unawaited(connectUsb());
    }
  }

  void _processNewReading(SoilReading raw) {
    _calibrationResult = DeepLearningCalibrator.calibrate(raw);
    _assessment = AgronomicAssessment.evaluate(displayReading);
  }

  void toggleAiCalibration([bool? enabled]) {
    _isAiCalibrationEnabled = enabled ?? !_isAiCalibrationEnabled;
    _assessment = AgronomicAssessment.evaluate(displayReading);
    notifyListeners();
  }

  Future<bool> connectUsb({int? baud}) async {
    final success = await _repository.connect(baudRate: baud);
    notifyListeners();
    return success;
  }

  Future<void> switchBaudRate(int baud) async {
    await _repository.switchBaudRate(baud);
    notifyListeners();
  }

  void toggleAutoBaud([bool? enable]) {
    _repository.toggleAutoBaud(enable);
    notifyListeners();
  }

  void toggleAutoConnect([bool? enable]) {
    _repository.toggleAutoConnect(enable);
    notifyListeners();
  }

  void setPollingInterval(int ms) {
    _repository.setPollingInterval(ms);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    notifyListeners();
  }

  void toggleSimulation() {
    if (isSimulationMode) {
      _repository.disconnect();
    } else {
      _repository.startSimulation();
    }
    notifyListeners();
  }

  Future<ExportResult> exportToSpreadsheet({String filename = 'Soil_parameters.csv'}) async {
    _isExporting = true;
    notifyListeners();

    try {
      final result = await _repository.exportHistory(filename: filename);
      if (result.success) {
        _lastExportPath = result.filePath;
      }
      return result;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> shareExport() async {
    if (_lastExportPath != null) {
      await ExportService.shareFile(_lastExportPath!);
    } else {
      final result = await exportToSpreadsheet();
      if (result.success && _lastExportPath != null) {
        await ExportService.shareFile(_lastExportPath!);
      }
    }
  }

  @override
  void dispose() {
    _readingSub?.cancel();
    _statusSub?.cancel();
    _telemetrySub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
