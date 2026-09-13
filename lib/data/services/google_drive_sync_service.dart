import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/soil_reading.dart';
import 'export_service.dart';
import 'soil_dataset_service.dart';

class GoogleDriveSyncStatus {
  final DateTime? lastSyncTime;
  final String webhookUrl;
  final int totalFiles;
  final double totalSizeBytes;
  final bool lastSyncSuccess;

  const GoogleDriveSyncStatus({
    this.lastSyncTime,
    this.webhookUrl = '',
    this.totalFiles = 0,
    this.totalSizeBytes = 0.0,
    this.lastSyncSuccess = false,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '${totalSizeBytes.toStringAsFixed(0)} B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}

/// Service handling Direct Google Drive Backup, system share intents,
/// and optional Google Apps Script Webhook Auto-Sync.
class GoogleDriveSyncService {
  GoogleDriveSyncService._();

  static const String _configFileName = 'google_drive_sync_config.json';

  static Future<File?> _getConfigFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_configFileName');
    } catch (_) {
      return null;
    }
  }

  /// Load current sync configuration and stats
  static Future<GoogleDriveSyncStatus> getSyncStatus() async {
    DateTime? lastSync;
    String webhook = '';

    try {
      final file = await _getConfigFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        if (json['lastSync'] != null) {
          lastSync = DateTime.tryParse(json['lastSync']);
        }
        webhook = json['webhookUrl'] ?? '';
      }
    } catch (e) {
      debugPrint('[GoogleDriveSync] Error loading config: $e');
    }

    // Calculate files and size in soil_dataset
    int fileCount = 0;
    double totalBytes = 0;
    try {
      final baseDir = await SoilDatasetService.getDatasetDirectory();
      if (await baseDir.exists()) {
        await for (final entity in baseDir.list(recursive: true)) {
          if (entity is File) {
            fileCount++;
            totalBytes += await entity.length();
          }
        }
      }
    } catch (_) {}

    final isSuccess = lastSync != null;

    return GoogleDriveSyncStatus(
      lastSyncTime: lastSync,
      webhookUrl: webhook,
      totalFiles: fileCount,
      totalSizeBytes: totalBytes,
      lastSyncSuccess: isSuccess,
    );
  }

  /// Save updated configuration
  static Future<void> saveConfig({required String webhookUrl, DateTime? lastSync}) async {
    try {
      final file = await _getConfigFile();
      if (file == null) return;
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }
      data['webhookUrl'] = webhookUrl;
      if (lastSync != null) {
        data['lastSync'] = lastSync.toIso8601String();
        data['lastSyncSuccess'] = true;
      }
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('[GoogleDriveSync] Error saving config: $e');
    }
  }

  /// Mark sync as completed now
  static Future<void> markSyncSuccess() async {
    try {
      final file = await _getConfigFile();
      if (file == null) return;
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }
      data['lastSync'] = DateTime.now().toIso8601String();
      data['lastSyncSuccess'] = true;
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  /// Backup all soil data logs and manifests to Google Drive
  static Future<bool> backupAllDatasetsToDrive({
    List<SoilReading> currentReadings = const [],
  }) async {
    final xFiles = <XFile>[];

    try {
      // 1. Export fresh CSV spreadsheet if readings exist
      if (currentReadings.isNotEmpty) {
        final res = await ExportService.exportToSpreadsheet(currentReadings);
        if (res.success && res.filePath.isNotEmpty) {
          xFiles.add(XFile(res.filePath));
        }
      }

      // 2. Include all CSV files in data/
      final dataDir = await SoilDatasetService.getDataDirectory();
      if (await dataDir.exists()) {
        final files = dataDir.listSync().whereType<File>().where((f) => f.path.endsWith('.csv'));
        for (final f in files) {
          if (!xFiles.any((x) => x.path == f.path)) {
            xFiles.add(XFile(f.path));
          }
        }
      }

      // 3. Include Dataset Manifest JSON
      final baseDir = await SoilDatasetService.getDatasetDirectory();
      final manifestFile = File('${baseDir.path}/${SoilDatasetService.manifestFileName}');
      if (await manifestFile.exists()) {
        xFiles.add(XFile(manifestFile.path));
      }

      if (xFiles.isEmpty) {
        // Create an empty summary placeholder if no files exist yet
        final tempDir = await getTemporaryDirectory();
        final dummyFile = File('${tempDir.path}/Soil_AI_Summary.txt');
        await dummyFile.writeAsString(
          'JC Digital Soil AI Analyzer - Cloud Backup\nTimestamp: ${DateTime.now()}\nStatus: Initialized\n',
        );
        xFiles.add(XFile(dummyFile.path));
      }

      // Trigger Android Share Sheet directed to Google Drive
      await Share.shareXFiles(
        xFiles,
        text: 'JC Digital Soil AI - สำรองข้อมูลขึ้น Google Drive\n'
            'โปรดเลือก "บันทึกไปยังไดรฟ์ (Save to Drive)" เพื่อจัดเก็บลงโฟลเดอร์งานวิจัย',
        subject: 'JC Digital Soil AI Google Drive Backup',
      );

      await markSyncSuccess();
      return true;
    } catch (e) {
      debugPrint('[GoogleDriveSync] Backup error: $e');
      return false;
    }
  }

  /// Backup photos and videos with telemetry overlays to Google Drive
  static Future<bool> syncMediaGalleryToDrive() async {
    final xFiles = <XFile>[];

    try {
      final imgDir = await SoilDatasetService.getImagesDirectory();
      if (await imgDir.exists()) {
        final files = imgDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.jpg') || f.path.toLowerCase().endsWith('.png'))
            .take(15);
        for (final f in files) {
          xFiles.add(XFile(f.path));
        }
      }

      final vidDir = await SoilDatasetService.getVideosDirectory();
      if (await vidDir.exists()) {
        final vids = vidDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.mp4'))
            .take(5);
        for (final v in vids) {
          xFiles.add(XFile(v.path));
        }
      }

      if (xFiles.isEmpty) return false;

      await Share.shareXFiles(
        xFiles,
        text: 'JC Digital Soil AI - สำรองภาพถ่ายและวิดีโอแปลงดินขึ้น Google Drive\n'
            'โปรดเลือก "บันทึกไปยังไดรฟ์ (Save to Drive)"',
        subject: 'Soil AI Field Photos & Videos Backup',
      );

      await markSyncSuccess();
      return true;
    } catch (e) {
      debugPrint('[GoogleDriveSync] Media sync error: $e');
      return false;
    }
  }

  /// Direct HTTP Upload to Google Apps Script Webhook (Automated Cloud Sync without share dialog)
  static Future<bool> syncViaWebhook({
    required String webhookUrl,
    required List<SoilReading> history,
  }) async {
    if (webhookUrl.isEmpty || !webhookUrl.startsWith('http')) return false;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(Uri.parse(webhookUrl));
      request.headers.set('content-type', 'application/json; charset=utf-8');

      final payload = {
        'source': 'JC_Digital_Soil_AI_App',
        'timestamp': DateTime.now().toIso8601String(),
        'recordCount': history.length,
        'readings': history.map((r) => r.toJson()).toList(),
      };

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      client.close();

      if (response.statusCode == 200 || response.statusCode == 302) {
        await markSyncSuccess();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[GoogleDriveSync] Webhook upload error: $e');
      return false;
    }
  }
}
