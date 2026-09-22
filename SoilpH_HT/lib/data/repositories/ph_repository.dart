import 'dart:async';
import '../models/ph_sensor_reading.dart';
import '../services/simulation_service.dart';
import '../services/usb_ph_service.dart';

class PhRepository {
  final UsbPhService _usbService;
  final SimulationService _simService;

  final _readingController = StreamController<SoilPhReading>.broadcast();
  Stream<SoilPhReading> get readingStream => _readingController.stream;

  final List<SoilPhReading> _history = [];
  List<SoilPhReading> get history => List.unmodifiable(_history);

  bool _isSimulationMode = true; // Default to simulation if no physical USB is detected
  bool get isSimulationMode => _isSimulationMode;

  StreamSubscription<SoilPhReading>? _usbSub;
  StreamSubscription<SoilPhReading>? _simSub;
  StreamSubscription<UsbStatus>? _statusSub;

  SoilPhReading _currentReading = SoilPhReading.initial();
  SoilPhReading get currentReading => _currentReading;

  PhRepository({
    UsbPhService? usbService,
    SimulationService? simService,
  })  : _usbService = usbService ?? UsbPhService(),
        _simService = simService ?? SimulationService() {
    _initStreams();
  }

  void _initStreams() {
    _usbSub = _usbService.readingStream.listen((r) {
      if (!_isSimulationMode) {
        _handleNewReading(r);
      }
    });

    _simSub = _simService.stream.listen((r) {
      if (_isSimulationMode) {
        _handleNewReading(r);
      }
    });

    // Auto-switch to live USB when hardware connects!
    _statusSub = _usbService.statusStream.listen((status) {
      if (status == UsbStatus.connected) {
        if (_isSimulationMode) {
          toggleSimulation(false);
        }
      }
    });

    if (_isSimulationMode) {
      _simService.start();
    }
  }

  void _handleNewReading(SoilPhReading reading) {
    _currentReading = reading;
    _history.insert(0, reading);
    if (_history.length > 500) {
      _history.removeLast();
    }
    _readingController.add(reading);
  }

  void toggleSimulation([bool? enable]) {
    _isSimulationMode = enable ?? !_isSimulationMode;
    if (_isSimulationMode) {
      _simService.start();
    } else {
      _simService.stop();
    }
  }

  void setScenario(SoilScenario scenario) {
    _simService.setScenario(scenario);
  }

  SoilScenario get currentScenario => _simService.scenario;

  // USB Pass-through
  Future<bool> connectUsb({int baudRate = 4800}) => _usbService.connect(baudRate: baudRate);
  Future<void> disconnectUsb() => _usbService.disconnect();
  Stream<UsbStatus> get usbStatusStream => _usbService.statusStream;
  UsbStatus get usbStatus => _usbService.status;
  int get baudRate => _usbService.currentBaudRate;

  void clearHistory() {
    _history.clear();
  }

  void dispose() {
    _usbSub?.cancel();
    _simSub?.cancel();
    _statusSub?.cancel();
    _usbService.dispose();
    _simService.dispose();
    _readingController.close();
  }
}
