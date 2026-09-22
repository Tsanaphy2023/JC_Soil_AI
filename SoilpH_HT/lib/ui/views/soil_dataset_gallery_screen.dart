import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/services/soil_dataset_service.dart';

class SoilDatasetGalleryScreen extends StatefulWidget {
  const SoilDatasetGalleryScreen({super.key});

  @override
  State<SoilDatasetGalleryScreen> createState() => _SoilDatasetGalleryScreenState();
}

class _SoilDatasetGalleryScreenState extends State<SoilDatasetGalleryScreen> {
  List<SoilPhotoRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final list = await SoilDatasetService.loadAllRecords();
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);

    return Scaffold(
      backgroundColor: PhColors.background,
      appBar: AppBar(
        title: const Text('คลังภาพถ่ายดิน & ข้อมูลภาคสนาม'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PhColors.neonGreen))
          : _records.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.white24),
                      SizedBox(height: 12),
                      Text(
                        'ยังไม่มีภาพถ่ายดินในคลัง\nแตะปุ่มกล้อง AI Vision เพื่อถ่ายภาพพร้อมฝัง HUD & พิกัด GPS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    final file = File(record.filePath);
                    final phColor = PhColors.getColorForPh(record.phCalibrated);

                    return InkWell(
                      onTap: () => _openDetail(context, record),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: PhColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PhColors.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Thumbnail
                            Expanded(
                              child: file.existsSync()
                                  ? Image.file(file, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade900,
                                      child: const Icon(Icons.broken_image, color: Colors.white30),
                                    ),
                            ),
                            // Metadata Footer
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'pH ${record.phCalibrated.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: phColor,
                                        ),
                                      ),
                                      Text(
                                        '${record.temperature.toStringAsFixed(1)}°C',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: PhColors.neonAmber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(record.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  if (record.location != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      record.location!.formattedCoordinates,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: PhColors.neonCyan.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _openDetail(BuildContext context, SoilPhotoRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoDetailScreen(
          record: record,
          onDeleted: () {
            _loadPhotos();
          },
        ),
      ),
    );
  }
}

class _PhotoDetailScreen extends StatelessWidget {
  final SoilPhotoRecord record;
  final VoidCallback onDeleted;

  const _PhotoDetailScreen({required this.record, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final file = File(record.filePath);
    final phColor = PhColors.getColorForPh(record.phCalibrated);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(record.id, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: PhColors.neonCyan),
            onPressed: () => SoilDatasetService.sharePhoto(record),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: PhColors.cardBg,
                  title: const Text('ลบภาพถ่ายนี้?'),
                  content: const Text('คุณต้องการลบภาพถ่ายภาคสนามนี้ออกจากคลังหรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('ยกเลิก'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: PhColors.neonRed),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('ลบข้อมูล', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await SoilDatasetService.deleteRecord(record);
                onDeleted();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Text('ไม่พบไฟล์รูปภาพ', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),
          Container(
            color: PhColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ค่า pH ชดเชย: ${record.phCalibrated.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: phColor,
                      ),
                    ),
                    Text(
                      'ค่า pH ดิบ: ${record.phRaw.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'อุณหภูมิดิน: ${record.temperature.toStringAsFixed(1)}°C  •  ความชื้น: ${record.moisture.toStringAsFixed(1)}%  •  EC: ${record.conductivity} µS/cm',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (record.location != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'พิกัด GPS: ${record.location!.summary}',
                    style: const TextStyle(fontSize: 11, color: PhColors.neonCyan),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
