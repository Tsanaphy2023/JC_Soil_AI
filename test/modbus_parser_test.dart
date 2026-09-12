import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/modbus_parser.dart';
import 'package:soil_app/data/models/soil_reading.dart';
import 'package:soil_app/domain/models/agronomic_assessment.dart';

void main() {
  group('ModbusParser & CRC-16 Tests', () {
    test('calculateCrc16 computes correct Modbus RTU checksum', () {
      // 01 03 00 00 00 08 -> CRC should be 0x0C44 (Low: 0x44, High: 0x0C)
      final command = [0x01, 0x03, 0x00, 0x00, 0x00, 0x08];
      final crc = ModbusParser.calculateCrc16(command);
      expect(crc, equals(0x0C44));
    });

    test('buildReadRequest produces valid 8-byte frame', () {
      final request = ModbusParser.buildReadRequest(
        slaveId: 0x01,
        startRegister: 0x0000,
        registerCount: 8,
      );
      expect(request.length, equals(8));
      expect(request[0], equals(0x01));
      expect(request[1], equals(0x03));
      expect(request[6], equals(0x44)); // CRC Low
      expect(request[7], equals(0x0C)); // CRC High
    });

    test('parseResponse decodes valid 8-register response frame correctly', () {
      // Payload:
      // Moisture: 54.2% -> 542 (0x021E)
      // Temperature: 28.5°C -> 285 (0x011D)
      // EC: 480 µS/cm -> 0x01E0
      // pH: 6.40 -> 64 (0x0040)
      // N: 125 mg/kg -> 0x007D
      // P: 38 mg/kg -> 0x0026
      // K: 185 mg/kg -> 0x00B9
      // Fertility: 348 mg/kg -> 0x015C
      final payload = [
        0x01, 0x03, 0x10,
        0x02, 0x1E, // Moisture
        0x01, 0x1D, // Temp
        0x01, 0xE0, // EC
        0x00, 0x40, // pH
        0x00, 0x7D, // N
        0x00, 0x26, // P
        0x00, 0xB9, // K
        0x01, 0x5C, // Fertility
      ];
      final crc = ModbusParser.calculateCrc16(payload);
      final frame = [...payload, crc & 0xFF, (crc >> 8) & 0xFF];

      final reading = ModbusParser.parseResponse(frame);
      expect(reading, isNotNull);
      expect(reading!.moisture, closeTo(54.2, 0.01));
      expect(reading.temperature, closeTo(28.5, 0.01));
      expect(reading.conductivity, equals(480));
      expect(reading.ph, closeTo(6.40, 0.01));
      expect(reading.nitrogen, equals(125));
      expect(reading.phosphorus, equals(38));
      expect(reading.potassium, equals(185));
      expect(reading.fertility, equals(348));
    });
  });

  group('Agronomic Assessment Tests', () {
    test('evaluates soil condition accurately', () {
      final reading = SoilReading.mock(
        temp: 28.0,
        moist: 50.0,
        ec: 500,
        phVal: 6.5,
        n: 120,
        p: 35,
        k: 180,
      );

      final assessment = AgronomicAssessment.evaluate(reading);
      expect(assessment.moistureStatus, equals(MoistureStatus.optimal));
      expect(assessment.salinityStatus, equals(SalinityStatus.optimal));
      expect(assessment.phStatus, equals(PhStatus.optimal));
    });
  });
}
