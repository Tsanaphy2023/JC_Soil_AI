import 'dart:async';
import 'dart:math';
import '../models/ph_sensor_reading.dart';

enum SoilScenario {
  tropicalHotDry('แปลงดินแล้งแดดจัด (Hot & Dry)', 38.5, 14.5, 1200, 5.35),
  waterloggedAcidic('แปลงที่ลุ่มน้ำขังดินเปรี้ยว (Waterlogged Acidic)', 27.5, 82.0, 380, 4.45),
  highlandCold('แปลงที่สูงอากาศหนาว (Highland Cold)', 14.2, 54.0, 290, 4.90),
  optimalGreenhouse('แปลงเรือนกระจกมาตรฐาน (Optimum Baseline)', 25.0, 50.0, 650, 6.50),
  alkalineSaline('ดินเค็มด่างชายทะเล (Coastal Alkaline Saline)', 33.0, 28.0, 4800, 8.45);

  final String title;
  final double baseTemp;
  final double baseMoist;
  final int baseEc;
  final double basePh;
  const SoilScenario(this.title, this.baseTemp, this.baseMoist, this.baseEc, this.basePh);
}

/// Dynamic Physics-Based Multi-Scenario Soil Simulation
class SimulationService {
  final _controller = StreamController<SoilPhReading>.broadcast();
  Stream<SoilPhReading> get stream => _controller.stream;

  Timer? _timer;
  SoilScenario _scenario = SoilScenario.tropicalHotDry;
  SoilScenario get scenario => _scenario;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final Random _rnd = Random();
  double _phase = 0.0;

  void setScenario(SoilScenario s) {
    _scenario = s;
    if (_isRunning) {
      _emitReading();
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _emitReading());
    _emitReading();
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void _emitReading() {
    _phase += 0.15;
    
    // Smooth micro-fluctuations simulating natural sensor noise & microclimate
    final double noiseT = sin(_phase * 0.7) * 0.4 + (_rnd.nextDouble() - 0.5) * 0.2;
    final double noiseM = cos(_phase * 0.5) * 0.6 + (_rnd.nextDouble() - 0.5) * 0.3;
    final double noiseEc = sin(_phase * 0.3) * 15 + (_rnd.nextInt(20) - 10);
    final double noisePh = sin(_phase * 0.9) * 0.04 + (_rnd.nextDouble() - 0.5) * 0.02;

    final double temp = (_scenario.baseTemp + noiseT).clamp(-20.0, 75.0);
    final double moist = (_scenario.baseMoist + noiseM).clamp(0.0, 100.0);
    final int ec = (_scenario.baseEc + noiseEc.toInt()).clamp(0, 20000);
    final double ph = (_scenario.basePh + noisePh).clamp(3.0, 10.0);

    final reading = SoilPhReading(
      phRaw: double.parse(ph.toStringAsFixed(2)),
      temperature: double.parse(temp.toStringAsFixed(1)),
      moisture: double.parse(moist.toStringAsFixed(1)),
      conductivity: ec,
      timestamp: DateTime.now(),
    );

    _controller.add(reading);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
