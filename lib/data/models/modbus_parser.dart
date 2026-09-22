import 'package:flutter/foundation.dart';
import 'soil_reading.dart';

/// Industrial Modbus RTU Frame Parser & CRC-16 Calculator
class ModbusParser {
  ModbusParser._();

  /// Calculate CRC-16 Modbus (Polynomial 0xA001, Initial 0xFFFF)
  static int calculateCrc16(List<int> data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte & 0xFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  /// Verify if the frame has a valid CRC-16 Modbus checksum
  static bool verifyCrc(List<int> frame) {
    if (frame.length < 4) return false;
    final payload = frame.sublist(0, frame.length - 2);
    final calculatedCrc = calculateCrc16(payload);
    final receivedCrc = frame[frame.length - 2] | (frame[frame.length - 1] << 8);
    return calculatedCrc == receivedCrc;
  }

  /// Construct a Modbus RTU Read Holding Registers Request Frame
  static Uint8List buildReadRequest({
    int slaveId = 0x01,
    int startRegister = 0x0000,
    int registerCount = 7, // Default 7 registers: Moisture, Temp, EC, pH, N, P, K
  }) {
    final frame = [
      slaveId,
      0x03,
      (startRegister >> 8) & 0xFF,
      startRegister & 0xFF,
      (registerCount >> 8) & 0xFF,
      registerCount & 0xFF,
    ];
    final crc = calculateCrc16(frame);
    frame.add(crc & 0xFF);         // CRC Low
    frame.add((crc >> 8) & 0xFF);  // CRC High
    return Uint8List.fromList(frame);
  }

  /// Parse Modbus RTU Response frame into a SoilReading object
  /// Supports:
  /// - 7 registers (14 data bytes, 19 bytes total): 7-in-1 Soil Probes
  /// - 8 registers (16 data bytes, 21 bytes total): 8-in-1 Soil Probes
  /// - 4 registers (8 data bytes, 13 bytes total): 4-in-1 Soil Probes
  static SoilReading? parseResponse(List<int> frame, {int expectedSlaveId = 0x01}) {
    if (frame.length < 13) return null;

    // First, check for Modbus Exception response (Function 0x83)
    for (int i = 0; i <= frame.length - 5; i++) {
      if (frame[i + 1] == 0x83) {
        final candidate = frame.sublist(i, i + 5);
        if (verifyCrc(candidate)) {
          debugPrint('[ModbusParser] Modbus Exception received from Slave 0x${frame[i].toRadixString(16)}: Error Code 0x${frame[i+2].toRadixString(16)}');
          break;
        }
      }
    }

    // Search for response header matching Function 0x03 and valid CRC
    int startIndex = -1;
    int payloadByteCount = 0;

    for (int i = 0; i <= frame.length - 13; i++) {
      // Slave ID check: either matches expectedSlaveId or if expectedSlaveId <= 0 accept any valid slave
      final matchesSlave = (expectedSlaveId <= 0) || (frame[i] == expectedSlaveId) || (frame[i] == 0x01) || (frame[i] == 0x02);
      if (matchesSlave && frame[i + 1] == 0x03) {
        final byteCount = frame[i + 2];
        if (byteCount == 14 || byteCount == 16 || byteCount == 8) {
          final expectedTotalLen = 3 + byteCount + 2;
          if (i + expectedTotalLen <= frame.length) {
            final candidate = frame.sublist(i, i + expectedTotalLen);
            if (verifyCrc(candidate)) {
              startIndex = i;
              payloadByteCount = byteCount;
              break;
            }
          }
        }
      }
    }

    if (startIndex == -1) return null;

    final sub = frame.sublist(startIndex);
    int offset = 3;

    // Register 0: Moisture (0.1 %)
    final rawMoist = (sub[offset] << 8) | sub[offset + 1];
    final moisture = rawMoist / 10.0;
    offset += 2;

    // Register 1: Temperature (0.1 °C, signed 16-bit)
    int rawTemp = (sub[offset] << 8) | sub[offset + 1];
    if (rawTemp >= 0x8000) rawTemp -= 0x10000;
    final temperature = rawTemp / 10.0;
    offset += 2;

    // Register 2: Conductivity EC (µS/cm)
    final conductivity = (sub[offset] << 8) | sub[offset + 1];
    offset += 2;

    // Register 3: pH (0.1 or 0.01 pH)
    final rawPh = (sub[offset] << 8) | sub[offset + 1];
    final ph = (rawPh > 140) ? (rawPh / 100.0) : (rawPh / 10.0);
    offset += 2;

    // Register 4, 5, 6: Nitrogen N, Phosphorus P, Potassium K (mg/kg)
    int nitrogen = 0;
    int phosphorus = 0;
    int potassium = 0;
    int fertility = (conductivity * 0.7).round();

    if (payloadByteCount >= 14) {
      nitrogen = (sub[offset] << 8) | sub[offset + 1];
      offset += 2;

      phosphorus = (sub[offset] << 8) | sub[offset + 1];
      offset += 2;

      potassium = (sub[offset] << 8) | sub[offset + 1];
      offset += 2;
    }

    // Register 7: Fertility (mg/kg) - if present in 8-register payload
    if (payloadByteCount >= 16 && (offset + 1) < sub.length - 2) {
      fertility = (sub[offset] << 8) | sub[offset + 1];
    }

    return SoilReading(
      temperature: temperature,
      moisture: moisture,
      conductivity: conductivity,
      ph: ph,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      fertility: fertility,
      timestamp: DateTime.now(),
    );
  }
}
