import 'dart:typed_data';

/// Modbus RTU CRC-16 Computation (Polynomial 0xA001)
class Crc16 {
  Crc16._();

  static int compute(Uint8List buffer, int length) {
    int crc = 0xFFFF;
    for (int pos = 0; pos < length; pos++) {
      crc ^= (buffer[pos] & 0xFF);
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

  static bool checkCrc(Uint8List data) {
    if (data.length < 3) return false;
    final int payloadLength = data.length - 2;
    final int computed = compute(data, payloadLength);
    final int received = (data[payloadLength + 1] << 8) | (data[payloadLength]);
    return computed == received;
  }
}
