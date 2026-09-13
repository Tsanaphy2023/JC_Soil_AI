import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/soil_dataset_item.dart';
import '../../data/services/soil_dataset_service.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import '../widgets/soil_video_player_viewer.dart';
import 'historical_data_screen.dart';

enum GalleryFilter { all, images, videos, csv }

class SoilDatasetGalleryScreen extends StatefulWidget {
  const SoilDatasetGalleryScreen({super.key});

  @override
  State<SoilDatasetGalleryScreen> createState() => _SoilDatasetGalleryScreenState();
}

class _SoilDatasetGalleryScreenState extends State<SoilDatasetGalleryScreen> {
  List<SoilDatasetItem> _items = [];
  List<SoilDataFileInfo> _dataFiles = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'images': 0,
    'videos': 0,
    'dataFiles': 0,
    'geotagged': 0,
    'formattedSize': '0 MB',
  };
  bool _isLoading = true;
  GalleryFilter _currentFilter = GalleryFilter.all;

  // Multi-Selection State for Batch Sharing & Batch Deletion
  bool _isSelectionMode = false;
  final Set<String> _selectedSampleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await SoilDatasetService.getAllDatasetItems();
      final stats = await SoilDatasetService.getDatasetStats();
      final dataFiles = await SoilDatasetService.getAllDataFiles();
      if (mounted) {
        setState(() {
          _items = items;
          _dataFiles = dataFiles;
          _stats = stats;
          _isLoading = false;
          // Clear any deleted items from selection
          final validIds = items.map((e) => e.sampleId).toSet();
          _selectedSampleIds.removeWhere((id) => !validIds.contains(id));
          if (_selectedSampleIds.isEmpty) {
            _isSelectionMode = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SoilDatasetItem> get _filteredItems {
    switch (_currentFilter) {
      case GalleryFilter.images:
        return _items.where((i) => i.isImage).toList();
      case GalleryFilter.videos:
        return _items.where((i) => i.isVideo).toList();
      case GalleryFilter.all:
      case GalleryFilter.csv:
        return _items;
    }
  }

  // Selection Mode Controllers
  void _toggleSelection(SoilDatasetItem item) {
    setState(() {
      if (_selectedSampleIds.contains(item.sampleId)) {
        _selectedSampleIds.remove(item.sampleId);
        if (_selectedSampleIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSampleIds.add(item.sampleId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedSampleIds.clear();
      for (final item in _filteredItems) {
        _selectedSampleIds.add(item.sampleId);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedSampleIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _shareSelectedItems(LanguageProvider lang) async {
    final selectedItems = _items.where((e) => _selectedSampleIds.contains(e.sampleId)).toList();
    if (selectedItems.isEmpty) return;

    try {
      await SoilDatasetService.shareMultipleItems(selectedItems);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('เกิดข้อผิดพลาดในการแชร์: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedItems(LanguageProvider lang) async {
    final selectedItems = _items.where((e) => _selectedSampleIds.contains(e.sampleId)).toList();
    if (selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              lang.t('deleteConfirmTitle'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '${lang.t('deleteConfirmBatch')}\n\n(${lang.t('selectedCount')}: ${selectedItems.length} รายการ)',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก / Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('${lang.t('deleteSelected')} (${selectedItems.length})', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await SoilDatasetService.deleteMultipleItems(selectedItems);
      _deselectAll();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('${lang.t('deletedSuccess')} ($count รายการ)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareItem(SoilDatasetItem item) async {
    try {
      await SoilDatasetService.shareItem(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('เกิดข้อผิดพลาดในการแชร์: $e'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteItem(SoilDatasetItem item, LanguageProvider lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(lang.t('deleteConfirmTitle'), style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          '${lang.t('deleteSingleConfirm')}\n\n• ${item.fileName}\n• ${item.sampleId}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก / Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบข้อมูล / Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SoilDatasetService.deleteDatasetItem(item);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(lang.t('deletedSuccess')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteDataFile(SoilDataFileInfo dataFile, LanguageProvider lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(lang.t('deleteConfirmTitle'), style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          '${lang.t('deleteSingleConfirm')}\n\n• ${dataFile.fileName}\n• ขนาด: ${dataFile.formattedSize}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก / Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบไฟล์ / Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SoilDatasetService.deleteDataFile(dataFile.filePath);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(lang.t('deletedSuccess')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _shareAllDataset() async {
    try {
      await SoilDatasetService.shareFullDatasetPackage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('ไม่สามารถแชร์ชุดข้อมูล: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.teal.shade900,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _deselectAll,
              ),
              title: Text(
                '${lang.t('selectedCount')}: ${_selectedSampleIds.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.cyanAccent),
                  tooltip: lang.t('selectAll'),
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: lang.t('shareSelected'),
                  onPressed: _selectedSampleIds.isEmpty ? null : () => _shareSelectedItems(lang),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  tooltip: lang.t('deleteSelected'),
                  onPressed: _selectedSampleIds.isEmpty ? null : () => _deleteSelectedItems(lang),
                ),
              ],
            )
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('galleryTitle'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    lang.t('gallerySubtitle'),
                    style: const TextStyle(fontSize: 10.5, color: Colors.cyanAccent),
                  ),
                ],
              ),
              backgroundColor: AppColors.cardSurface,
              actions: [
                if (_filteredItems.isNotEmpty && _currentFilter != GalleryFilter.csv)
                  IconButton(
                    icon: const Icon(Icons.checklist, color: Colors.cyanAccent),
                    tooltip: lang.t('selectFiles'),
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.cyanAccent),
                  tooltip: lang.t('shareDataset'),
                  onPressed: _items.isEmpty ? null : _shareAllDataset,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Refresh',
                  onPressed: _loadData,
                ),
              ],
            ),
      body: Column(
        children: [
          // 1. Top Statistics Header Card (Images, Videos, Data, Storage)
          _buildStatsCard(lang),

          // 2. Filter Tabs (All, Photos, Videos, CSV & Data)
          _buildFilterTabs(lang),

          // 3. Main Content (Grid or CSV List)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _currentFilter == GalleryFilter.csv
                    ? _buildCsvTabContent(lang)
                    : _buildMediaGrid(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('📷 ${lang.t('photosCount')}', '${_stats['images'] ?? 0}', Colors.tealAccent),
              _buildStatDivider(),
              _buildStatColumn('🎥 ${lang.t('videosCount')}', '${_stats['videos'] ?? 0}', Colors.redAccent),
              _buildStatDivider(),
              _buildStatColumn('📊 ${lang.t('filterCsv')}', '${_dataFiles.length}', Colors.greenAccent),
              _buildStatDivider(),
              _buildStatColumn('💾 ${lang.t('storageSize')}', '${_stats['formattedSize'] ?? '0 MB'}', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_copy_outlined, size: 13, color: Colors.cyanAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lang.t('subfoldersOrganized'),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 28, width: 1, color: Colors.white12);
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip('${lang.t('filterAll')} (${_items.length})', GalleryFilter.all),
          const SizedBox(width: 6),
          _buildFilterChip('📷 ${lang.t('filterPhotos')} (${_stats['images'] ?? 0})', GalleryFilter.images),
          const SizedBox(width: 6),
          _buildFilterChip('🎥 ${lang.t('filterVideos')} (${_stats['videos'] ?? 0})', GalleryFilter.videos),
          const SizedBox(width: 6),
          _buildFilterChip('📊 ${lang.t('filterCsv')} (${_dataFiles.length})', GalleryFilter.csv),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, GalleryFilter filter) {
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyan.shade900 : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(LanguageProvider lang) {
    final items = _filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              lang.currentLanguage == AppLanguage.chinese
                  ? '暂无保存的土壤图片或视频'
                  : (lang.currentLanguage == AppLanguage.english
                      ? 'No photos or videos recorded yet'
                      : 'ยังไม่มีภาพถ่ายหรือวิดีโอที่บันทึกไว้'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              lang.currentLanguage == AppLanguage.chinese
                  ? '点击主界面上的 "AI视觉与GPS" 按钮即可拍摄包含土壤参数的图像'
                  : (lang.currentLanguage == AppLanguage.english
                      ? 'Tap "AI Vision & GPS" on home screen to capture samples'
                      : 'แตะปุ่ม "AI Vision & GPS" ที่หน้าหลักเพื่อถ่ายภาพพร้อมพารามิเตอร์ดิน'),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMediaCard(item, lang);
          },
        );
      },
    );
  }

  Widget _buildMediaCard(SoilDatasetItem item, LanguageProvider lang) {
    final isSelected = _selectedSampleIds.contains(item.sampleId);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item);
        } else {
          _openDetailViewer(item, lang);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedSampleIds.add(item.sampleId);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent
                : (_isSelectionMode ? Colors.white24 : Colors.white12),
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.cyanAccent.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Media Preview Image or Video Placeholder
            Positioned.fill(
              child: item.isImage && item.fileExists
                  ? Image.file(
                      File(item.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderMedia(item),
                    )
                  : _buildPlaceholderMedia(item),
            ),

            // Selection tint overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  color: Colors.cyan.withValues(alpha: 0.22),
                ),
              ),

            // Top Gradient & Info/Action Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isSelectionMode)
                      // Checkbox in selection mode
                      GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.cyanAccent : Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70),
                          ),
                          child: Icon(
                            isSelected ? Icons.check : Icons.circle_outlined,
                            color: isSelected ? Colors.black : Colors.white70,
                            size: 15,
                          ),
                        ),
                      )
                    else if (item.latitude != 0.0 || item.longitude != 0.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.cyanAccent, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${item.latitude.toStringAsFixed(3)}°, ${item.longitude.toStringAsFixed(3)}°',
                              style: const TextStyle(color: Colors.white, fontSize: 9.5),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Action buttons (share & delete) when not in selection mode
                    if (!_isSelectionMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _shareItem(item),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Icon(Icons.share, color: Colors.cyanAccent, size: 13),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _confirmDeleteItem(item, lang),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 13),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Gradient with Telemetry Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.formattedShortDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'pH ${item.ph.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${item.moisture.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          'N-P-K: ${item.nitrogen}-${item.phosphorus}-${item.potassium}',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Video Center Play Indicator
            if (item.isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderMedia(SoilDatasetItem item) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.isVideo ? Icons.videocam : Icons.photo,
              color: item.isVideo ? Colors.redAccent : Colors.tealAccent,
              size: 38,
            ),
            const SizedBox(height: 6),
            Text(
              item.isVideo ? 'วิดีโอแปลงดิน (${item.durationSeconds ?? 0}s)' : 'ภาพถ่ายดิน',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              item.formattedFileSize,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Viewer Modal with Pinch-to-zoom and Full Telemetry
  void _openDetailViewer(SoilDatasetItem item, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF14171C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Top Drag Handle & Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.sampleId,
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              item.formattedDate,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.cyanAccent),
                              tooltip: 'แชร์ตัวอย่างนี้',
                              onPressed: () => _shareItem(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'ลบ',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDeleteItem(item, lang);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(14),
                      children: [
                        // Media Display Box (In-App Video Player with Telemetry HUD for videos, Pinch-to-zoom for images)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: item.isVideo ? 420 : 280,
                            color: Colors.black,
                            child: item.isVideo && item.fileExists
                                ? SoilVideoPlayerViewer(item: item)
                                : item.isImage && item.fileExists
                                    ? InteractiveViewer(
                                        minScale: 0.8,
                                        maxScale: 4.0,
                                        child: Image.file(
                                          File(item.filePath),
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item.isVideo ? Icons.videocam_off : Icons.broken_image,
                                              color: item.isVideo ? Colors.redAccent : Colors.grey,
                                              size: 50,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.fileName,
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                            if (item.isVideo)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                                                  icon: const Icon(Icons.share),
                                                  label: const Text('แชร์ไฟล์วิดีโอ'),
                                                  onPressed: () => _shareItem(item),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // GPS Location Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.location_on, color: Colors.cyanAccent, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'พิกัดดาวเทียม GPS ประจำจุดตัวอย่าง',
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'ขนาดไฟล์: ${item.formattedFileSize}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.formattedGps,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.cyanAccent,
                                    side: const BorderSide(color: Colors.cyanAccent),
                                  ),
                                  icon: const Icon(Icons.map_outlined, size: 16),
                                  label: const Text('ดูตำแหน่งบน Google Maps / แชร์พิกัด', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _shareItem(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 8-in-1 Sensor Ground-Truth Telemetry Grid
                        const Text(
                          '📊 ค่าตรวจวัดดิน 8-in-1 (Sensor Ground-Truth):',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            _buildTelemetryTile('อุณหภูมิ (Temp)', '${item.temperature.toStringAsFixed(1)} °C', AppColors.temperature),
                            _buildTelemetryTile('ความชื้น (Moist)', '${item.moisture.toStringAsFixed(1)} %', AppColors.moisture),
                            _buildTelemetryTile('การนำไฟฟ้า (EC)', '${item.conductivity} µS/cm', AppColors.conductivity),
                            _buildTelemetryTile('ความเป็นกรด-ด่าง (pH)', item.ph.toStringAsFixed(2), AppColors.ph),
                            _buildTelemetryTile('ไนโตรเจน (N)', '${item.nitrogen} mg/kg', AppColors.nitrogen),
                            _buildTelemetryTile('ฟอสฟอรัส (P)', '${item.phosphorus} mg/kg', AppColors.phosphorus),
                            _buildTelemetryTile('โพแทสเซียม (K)', '${item.potassium} mg/kg', AppColors.potassium),
                            _buildTelemetryTile('ความอุดมสมบูรณ์', '${item.fertility}', AppColors.fertility),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // AI PINN Calibration Telemetry Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade900.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                    Icon(Icons.psychology, color: Colors.tealAccent, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'AI PINN (Physics-Informed Neural Network) Output',
                                      style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (item.aiConfidenceScore != null)
                                Text(
                                  '• ความเชื่อมั่น (Confidence Score): ${(item.aiConfidenceScore! * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              Text(
                                '• pH สอบเทียบ: ${item.aiPh?.toStringAsFixed(2) ?? item.ph.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                '• EC สอบเทียบ: ${item.aiConductivity ?? item.conductivity} µS/cm',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                '• ความชื้นสอบเทียบ: ${item.aiMoisture?.toStringAsFixed(1) ?? item.moisture.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Main Action Button (Share to Line, Drive, Email, etc.)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text(
                            'แชร์ตัวอย่างนี้ (Share Image & Telemetry)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _shareItem(item),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTelemetryTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 4: CSV Logs & Spreadsheets Management in soil_dataset/data/
  Widget _buildCsvTabContent(LanguageProvider lang) {
    final vm = context.watch<SoilSensorViewModel>();
    final history = vm.history;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Live memory session card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'รอบตรวจวัดปัจจุบัน (Live Sensor Buffer)',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ข้อมูลในหน่วยความจำ RAM ชั่วคราว: ${history.length} รายการ (ส่งออกเป็น CSV อัตโนมัติ)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('แชร์ CSV สด', style: TextStyle(fontSize: 12)),
                      onPressed: history.isEmpty ? null : () => vm.shareExport(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                      ),
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('ดูตารางย้อนหลัง', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoricalDataScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section header for persistent data folder
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_open, color: Colors.amberAccent, size: 18),
                SizedBox(width: 6),
                Text(
                  'คลังไฟล์ข้อมูล soil_dataset/data/',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${_dataFiles.length} ไฟล์',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_dataFiles.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 40, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  const Text(
                    'ยังไม่มีไฟล์ข้อมูลในโฟลเดอร์ data/',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ..._dataFiles.map((df) => _buildDataFileItem(df, lang)),
      ],
    );
  }

  Widget _buildDataFileItem(SoilDataFileInfo dataFile, LanguageProvider lang) {
    final isManifest = dataFile.fileName == SoilDatasetService.manifestFileName;
    final isCsv = dataFile.isCsv;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isManifest ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCsv
                  ? Colors.green.shade900.withValues(alpha: 0.4)
                  : Colors.amber.shade900.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCsv ? Icons.table_chart : Icons.data_object,
              color: isCsv ? Colors.greenAccent : Colors.amberAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataFile.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${dataFile.formattedSize} • ${dataFile.formattedDate}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.cyanAccent, size: 18),
            tooltip: 'แชร์ไฟล์',
            onPressed: () async {
              try {
                await SoilDatasetService.shareDataFile(dataFile.filePath);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade900,
                      content: Text('แชร์ไฟล์ไม่สำเร็จ: $e'),
                    ),
                  );
                }
              }
            },
          ),
          if (!isManifest)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              tooltip: 'ลบไฟล์',
              onPressed: () => _confirmDeleteDataFile(dataFile, lang),
            ),
        ],
      ),
    );
  }
}
