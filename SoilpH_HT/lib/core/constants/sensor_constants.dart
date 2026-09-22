import 'dart:typed_data';

/// Modbus RTU Sensor Constants & Physical Bounds
class SensorConstants {
  SensorConstants._();

  // Modbus Command: Read 4 or 8 Registers (Slave ID 0x01, Function 0x03)
  // Moisture (0x00), Temp (0x01), EC (0x02), pH (0x03)
  static final Uint8List readHoldingRegistersCommand = Uint8List.fromList([
    0x01, 0x03, 0x00, 0x00, 0x00, 0x04, 0x44, 0x09,
  ]);

  // Extended 8-parameter command (Backward compatibility with 8-in-1 probes)
  static final Uint8List read8In1Command = Uint8List.fromList([
    0x01, 0x03, 0x00, 0x00, 0x00, 0x08, 0x44, 0x0C,
  ]);

  // Default Communication Settings
  static const int defaultBaudRate = 4800;
  static const List<int> supportedBaudRates = [4800, 9600, 19200, 115200];
  static const int defaultPollingIntervalMs = 400; // 2.5 Hz

  // Physical Sensor Boundaries (Sanity checks)
  static const double minPh = 3.00;
  static const double maxPh = 10.00;
  static const double minTemperature = -20.0;
  static const double maxTemperature = 75.0;
  static const double minMoisture = 0.0;
  static const double maxMoisture = 100.0;
  static const int minEc = 0;
  static const int maxEc = 20000;

  // Reference Standard Constants for Deep Learning Normalization
  static const double referenceTemperature = 25.0; // °C (Nernst standard reference)
  static const double referenceMoisture = 50.0;    // % VWC (Field capacity optimum)
  static const double referenceEc = 600.0;         // µS/cm (Typical non-saline soil solution)
}
