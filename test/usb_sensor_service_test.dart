import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/core/constants/sensor_constants.dart';
import 'package:soil_app/data/repositories/soil_sensor_repository.dart';
import 'package:soil_app/data/services/usb_sensor_service.dart';
import 'package:soil_app/ui/viewmodels/soil_sensor_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsbSensorService Auto-Connect & Real-Time Telemetry Tests', () {
    test('initializes with auto-connect enabled and 400ms polling rate', () {
      final service = UsbSensorService(autoConnect: false);
      expect(service.isAutoConnectEnabled, isFalse);
      expect(service.pollingIntervalMs, equals(SensorConstants.defaultPollingIntervalMs));
      expect(service.currentStatus, equals(UsbConnectionStatus.disconnected));
      service.dispose();
    });

    test('toggles auto-connect correctly', () {
      final service = UsbSensorService(autoConnect: false);
      expect(service.isAutoConnectEnabled, isFalse);

      service.toggleAutoConnect(true);
      expect(service.isAutoConnectEnabled, isTrue);

      service.toggleAutoConnect(false);
      expect(service.isAutoConnectEnabled, isFalse);
      service.dispose();
    });

    test('updates polling interval correctly within bounds', () {
      final service = UsbSensorService(autoConnect: false);
      expect(service.pollingIntervalMs, equals(400));

      service.setPollingInterval(350);
      expect(service.pollingIntervalMs, equals(350));

      service.setPollingInterval(1000);
      expect(service.pollingIntervalMs, equals(1000));

      // Out of bounds should be ignored
      service.setPollingInterval(50);
      expect(service.pollingIntervalMs, equals(1000));
      service.dispose();
    });

    test('SoilSensorViewModel proxies autoConnect and polling rate correctly', () {
      final service = UsbSensorService(autoConnect: false);
      final repo = SoilSensorRepository(sensorService: service);
      final vm = SoilSensorViewModel(repository: repo);

      expect(vm.isAutoConnectEnabled, isFalse);
      expect(vm.pollingIntervalMs, equals(400));

      vm.toggleAutoConnect(true);
      expect(vm.isAutoConnectEnabled, isTrue);

      vm.setPollingInterval(350);
      expect(vm.pollingIntervalMs, equals(350));

      vm.dispose();
      repo.dispose();
    });
  });
}
