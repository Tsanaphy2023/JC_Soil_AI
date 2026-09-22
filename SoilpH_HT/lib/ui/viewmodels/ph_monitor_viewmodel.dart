import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/geo_location_data.dart';
import '../../data/models/ph_sensor_reading.dart';
import '../../data/repositories/ph_repository.dart';
import '../../data/services/export_service.dart';
import '../../data/services/geo_location_service.dart';
import '../../data/services/simulation_service.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/usb_ph_service.dart';
import '../../domain/ml/ph_deep_pinn_model.dart';
import '../../domain/models/agronomic_rules.dart';
import '../../domain/models/lime_prescription.dart';

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

  bool _isAiEnabled = true;
  bool get isAiEnabled => _isAiEnabled;

  double get displayPh => _isAiEnabled ? _calibratedResult.phCalibrated : _rawReading.phRaw;

  final List<CalibratedPhResult> _historyLog = [];
  List<CalibratedPhResult> get historyLog => List.unmodifiable(_historyLog);

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
  }

  void _processReading(SoilPhReading reading) {
    _calibratedResult = PhDeepPinnModel.compensate(reading);
    _historyLog.insert(0, _calibratedResult);
    if (_historyLog.length > 500) {
      _historyLog.removeLast();
    }
  }

  void toggleAi([bool? enable]) {
    _isAiEnabled = enable ?? !_isAiEnabled;
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
