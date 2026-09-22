import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ai_training_sample.dart';
import '../../data/models/field_validation_record.dart';
import '../../data/models/geo_location_data.dart';
import '../../data/models/ph_sensor_reading.dart';
import '../../data/repositories/ph_repository.dart';
import '../../data/services/export_service.dart';
import '../../data/services/field_benchmark_service.dart';
import '../../data/services/geo_location_service.dart';
import '../../data/services/simulation_service.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/usb_ph_service.dart';
import '../../domain/ml/ph_deep_pinn_model.dart';
import '../../domain/models/agronomic_rules.dart';
import '../../domain/models/lime_prescription.dart';

enum PhCalibrationMode {
  fullAiPinn('AI PINN ชดเชยสมบูรณ์ (Temp + Non-Linear)'),
  conventionalAtc('ATC ดั้งเดิม (ชดเชยอุณหภูมิเชิงเส้น)'),
  rawUncompensated('ค่าดิบเซนเซอร์ (Raw Uncompensated)');

  final String label;
  const PhCalibrationMode(this.label);
}

class PhMonitorViewModel extends ChangeNotifier {
  final PhRepository _repository;
  final GeoLocationService _locationService;
  StreamSubscription<SoilPhReading>? _readingSub;
  StreamSubscription<UsbStatus>? _statusSub;
  StreamSubscription<GeoLocationData>? _locationSub;

  SoilPhReading _rawReading = SoilPhReading.initial();
  SoilPhReading get rawReading => _rawReading;

  CalibratedPhResult _calibratedResult = PhDeepPinnModel.compensate(SoilPhReading.initial());
  CalibratedPhResult get calibratedResult => _calibratedResult;

  PhCalibrationMode _calibrationMode = PhCalibrationMode.fullAiPinn;
  PhCalibrationMode get calibrationMode => _calibrationMode;

  bool get isAiEnabled => _calibrationMode == PhCalibrationMode.fullAiPinn;

  double get displayPh {
    switch (_calibrationMode) {
      case PhCalibrationMode.fullAiPinn:
        return _calibratedResult.phCalibrated;
      case PhCalibrationMode.conventionalAtc:
        return _calibratedResult.atcPh;
      case PhCalibrationMode.rawUncompensated:
        return _rawReading.phRaw;
    }
  }

  final List<CalibratedPhResult> _historyLog = [];
  List<CalibratedPhResult> get historyLog => List.unmodifiable(_historyLog);

  // Field Validation & Benchmark records (Objective 3)
  List<FieldValidationRecord> _validationRecords = [];
  List<FieldValidationRecord> get validationRecords => List.unmodifiable(_validationRecords);
  BenchmarkStatistics _benchmarkStats = BenchmarkStatistics.empty();
  BenchmarkStatistics get benchmarkStats => _benchmarkStats;

  // AI Training Dataset samples (Objective 1)
  List<AiTrainingSample> _aiTrainingSamples = [];
  List<AiTrainingSample> get aiTrainingSamples => List.unmodifiable(_aiTrainingSamples);

  SoilTexture _selectedTexture = SoilTexture.loamy;
  SoilTexture get selectedTexture => _selectedTexture;

  LimePrescription get limePrescription => LimePrescription.calculate(
        currentPh: displayPh,
        texture: _selectedTexture,
      );

  List<NutrientAvailability> get nutrients => AgronomicRules.evaluateNutrients(displayPh);

  String? get toxicityAlert => AgronomicRules.checkToxicityWarning(displayPh);

  UsbStatus _usbStatus = UsbStatus.disconnected;
  UsbStatus get usbStatus => _usbStatus;

  bool get isSimulationMode => _repository.isSimulationMode;
  SoilScenario get currentScenario => _repository.currentScenario;
  int get baudRate => _repository.baudRate;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _lastExportPath;
  String? get lastExportPath => _lastExportPath;

  GeoLocationData get currentLocation => _locationService.currentLocation;

  PhMonitorViewModel({
    PhRepository? repository,
    GeoLocationService? locationService,
  })  : _repository = repository ?? PhRepository(),
        _locationService = locationService ?? GeoLocationService() {
    _rawReading = _repository.currentReading;
    _processReading(_rawReading);

    _readingSub = _repository.readingStream.listen((reading) {
      _rawReading = reading;
      _processReading(reading);
      notifyListeners();
    });

    _statusSub = _repository.usbStatusStream.listen((status) {
      _usbStatus = status;
      notifyListeners();
    });

    _locationSub = _locationService.locationStream.listen((_) {
      notifyListeners();
    });

    // Load benchmarks on launch
    _loadBenchmarkData();
  }

  Future<void> _loadBenchmarkData() async {
    try {
      _validationRecords = await FieldBenchmarkService.loadValidationRecords();
      _benchmarkStats = BenchmarkStatistics.compute(_validationRecords);
      _aiTrainingSamples = await FieldBenchmarkService.loadAiSamples();
      notifyListeners();
    } catch (_) {}
  }

  void _processReading(SoilPhReading reading) {
    _calibratedResult = PhDeepPinnModel.compensate(reading);
    _historyLog.insert(0, _calibratedResult);
    if (_historyLog.length > 500) {
      _historyLog.removeLast();
    }
  }

  void setCalibrationMode(PhCalibrationMode mode) {
    _calibrationMode = mode;
    notifyListeners();
  }

  void toggleAi([bool? enable]) {
    if (enable != null) {
      _calibrationMode = enable ? PhCalibrationMode.fullAiPinn : PhCalibrationMode.rawUncompensated;
    } else {
      _calibrationMode = _calibrationMode == PhCalibrationMode.fullAiPinn
          ? PhCalibrationMode.rawUncompensated
          : PhCalibrationMode.fullAiPinn;
    }
    notifyListeners();
  }

  void toggleSimulation([bool? enable]) {
    _repository.toggleSimulation(enable);
    notifyListeners();
  }

  void setScenario(SoilScenario scenario) {
    _repository.setScenario(scenario);
    notifyListeners();
  }

  void setSoilTexture(SoilTexture texture) {
    _selectedTexture = texture;
    notifyListeners();
  }

  Future<bool> connectUsb({int baudRate = 4800}) async {
    final success = await _repository.connectUsb(baudRate: baudRate);
    notifyListeners();
    return success;
  }

  Future<void> disconnectUsb() async {
    await _repository.disconnectUsb();
    notifyListeners();
  }

  Future<SoilPhotoRecord> captureAndSaveSoilPhoto(Uint8List rawBytes) async {
    final record = await SoilDatasetService.saveCapturedPhoto(
      rawImageBytes: rawBytes,
      result: _calibratedResult,
      location: currentLocation,
    );
    notifyListeners();
    return record;
  }

  // Objective 3: Add Field Validation Record
  Future<void> addFieldValidationRecord({
    required String province,
    required String district,
    required String orchardName,
    required String durianVariety,
    required double standardPh,
  }) async {
    final record = FieldValidationRecord(
      id: 'FLD_${DateFormat('yyMMdd_HHmmss').format(DateTime.now())}',
      province: province,
      district: district,
      orchardName: orchardName,
      durianVariety: durianVariety,
      standardPhMeterReading: standardPh,
      portableAiPhReading: _calibratedResult.phCalibrated,
      portableRawPhReading: _rawReading.phRaw,
      portableAtcPhReading: _calibratedResult.atcPh,
      sensorVoltageMv: _calibratedResult.sensorVoltageMv,
      temperatureC: _rawReading.temperature,
      moisturePct: _rawReading.moisture,
      ecUsCm: _rawReading.conductivity,
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      elevation: currentLocation.altitude,
      timestamp: DateTime.now(),
    );

    await FieldBenchmarkService.addValidationRecord(record);
    _validationRecords = await FieldBenchmarkService.loadValidationRecords();
    _benchmarkStats = BenchmarkStatistics.compute(_validationRecords);
    notifyListeners();
  }

  Future<void> deleteValidationRecord(String id) async {
    await FieldBenchmarkService.deleteValidationRecord(id);
    _validationRecords = await FieldBenchmarkService.loadValidationRecords();
    _benchmarkStats = BenchmarkStatistics.compute(_validationRecords);
    notifyListeners();
  }

  Future<String> exportValidationCsv() async {
    return await FieldBenchmarkService.exportValidationCsv();
  }

  // Objective 1: Add AI Training Sample
  Future<void> addAiTrainingSample({
    required String sampleType,
    required double standardPh,
  }) async {
    final slope = SoilPhReading.nernstSlope(_rawReading.temperature);
    final theoreticalMv = -slope * (standardPh - 7.0);
    final residualMv = _calibratedResult.sensorVoltageMv - theoreticalMv;

    final sample = AiTrainingSample(
      sampleId: 'TRN_${DateFormat('yyMMdd_HHmmss').format(DateTime.now())}',
      sampleType: sampleType,
      sensorVoltageMv: _calibratedResult.sensorVoltageMv,
      temperatureC: _rawReading.temperature,
      standardPh: standardPh,
      rawPh: _rawReading.phRaw,
      moisturePct: _rawReading.moisture,
      ecUsCm: _rawReading.conductivity,
      nernstTheoreticalMv: theoreticalMv,
      residualMv: residualMv,
      timestamp: DateTime.now(),
    );

    await FieldBenchmarkService.addAiSample(sample);
    _aiTrainingSamples = await FieldBenchmarkService.loadAiSamples();
    notifyListeners();
  }

  Future<void> deleteAiSample(String sampleId) async {
    await FieldBenchmarkService.deleteAiSample(sampleId);
    _aiTrainingSamples = await FieldBenchmarkService.loadAiSamples();
    notifyListeners();
  }

  Future<String> exportAiDatasetCsv() async {
    return await FieldBenchmarkService.exportAiDatasetCsv();
  }

  Future<String?> exportCsv() async {
    if (_historyLog.isEmpty) return null;
    _isExporting = true;
    notifyListeners();

    try {
      final path = await ExportService.exportToCsv(_historyLog);
      _lastExportPath = path;
      await ExportService.shareFile(path);
      return path;
    } catch (_) {
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _historyLog.clear();
    _repository.clearHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _readingSub?.cancel();
    _statusSub?.cancel();
    _locationSub?.cancel();
    _locationService.dispose();
    _repository.dispose();
    super.dispose();
  }
}
