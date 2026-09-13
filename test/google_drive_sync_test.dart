import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/services/google_drive_sync_service.dart';
import 'package:soil_app/data/models/soil_reading.dart';

void main() {
  group('GoogleDriveSyncStatus Model Tests', () {
    test('initializes with default values and formats size correctly', () {
      const status = GoogleDriveSyncStatus(
        webhookUrl: 'https://example.com/webhook',
        totalFiles: 12,
        totalSizeBytes: 1048576, // 1 MB
        lastSyncSuccess: true,
      );

      expect(status.webhookUrl, 'https://example.com/webhook');
      expect(status.totalFiles, 12);
      expect(status.totalSizeBytes, 1048576);
      expect(status.lastSyncSuccess, true);
      expect(status.formattedSize, '1.00 MB');
    });

    test('formats smaller bytes correctly', () {
      const bytesStatus = GoogleDriveSyncStatus(totalSizeBytes: 512);
      expect(bytesStatus.formattedSize, '512 B');

      const kbStatus = GoogleDriveSyncStatus(totalSizeBytes: 20480); // 20 KB
      expect(kbStatus.formattedSize, '20.0 KB');
    });
  });

  group('GoogleDriveSyncService Tests', () {
    test('syncViaWebhook rejects invalid or empty URLs', () async {
      final invalidResult = await GoogleDriveSyncService.syncViaWebhook(
        webhookUrl: '',
        history: [SoilReading.mock()],
      );
      expect(invalidResult, false);

      final notHttp = await GoogleDriveSyncService.syncViaWebhook(
        webhookUrl: 'ftp://not-supported',
        history: [],
      );
      expect(notHttp, false);
    });
  });
}
