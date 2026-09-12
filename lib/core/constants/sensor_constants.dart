/// Constants for Soil 8-in-1 Modbus RTU / USB OTG Sensor
class SensorConstants {
  SensorConstants._();

  // Serial Communication Defaults
  static const int defaultBaudRate = 4800;
  static const List<int> supportedBaudRates = [2400, 4800, 9600, 19200, 115200];
  static const int defaultSlaveId = 0x01;
  static const int pollingIntervalMs = 1500;

  // Modbus RTU Request Commands
  // 01 03 00 00 00 08 44 0C -> Read 8 registers starting at 0x0000
  static const List<int> read8RegistersCommand = [
    0x01, 0x03, 0x00, 0x00, 0x00, 0x08, 0x44, 0x0C
  ];

  // 01 03 00 00 00 07 04 08 -> Read 7 registers starting at 0x0000
  static const List<int> read7RegistersCommand = [
    0x01, 0x03, 0x00, 0x00, 0x00, 0x07, 0x04, 0x08
  ];

  // Titles & Units
  static const String titleTemperature = 'Temperature';
  static const String unitTemperature = '°C';

  static const String titleMoisture = 'Moisture';
  static const String unitMoisture = '%';

  static const String titleConductivity = 'Conductivity(EC)';
  static const String unitConductivity = 'us/cm';

  static const String titlePh = 'pH';
  static const String unitPh = 'PH';

  static const String titleNitrogen = '(N)';
  static const String unitNitrogen = 'mg/kg';

  static const String titlePhosphorus = '(P)';
  static const String unitPhosphorus = 'mg/kg';

  static const String titlePotassium = '(K)';
  static const String unitPotassium = 'mg/kg';

  static const String titleFertility = 'Fertility';
  static const String unitFertility = 'mg/kg';

  // Excel / Log filename
  static const String defaultFileName = 'Soil_parameters.xlsx';
  static const String defaultCsvFileName = 'Soil_parameters.csv';
  static const String appVersion = 'v1.0.1';
}
