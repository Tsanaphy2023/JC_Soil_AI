import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import 'soil_dataset_gallery_screen.dart';

class HistoricalDataScreen extends StatelessWidget {
  const HistoricalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoilSensorViewModel>();
    final history = vm.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Soil Measurement Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.cyanAccent),
            tooltip: 'คลังภาพ & วิดีโอ (Photo/Video Gallery)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV/Excel',
            onPressed: history.isEmpty ? null : () => vm.shareExport(),
          ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage_outlined, size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    'No measurements recorded yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect the USB sensor or start Demo Simulation.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary Statistics Strip (Responsive Auto-Scaling)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: AppColors.cardSurface,
                  child: Row(
                    children: [
                      Expanded(child: _buildStatItem('Records', '${history.length}')),
                      Expanded(
                        child: _buildStatItem(
                          'Avg Temp',
                          '${(history.map((e) => e.temperature).reduce((a, b) => a + b) / history.length).toStringAsFixed(1)} °C',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Avg Moist',
                          '${(history.map((e) => e.moisture).reduce((a, b) => a + b) / history.length).toStringAsFixed(1)} %',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Avg pH',
                          (history.map((e) => e.ph).reduce((a, b) => a + b) / history.length).toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),

                // Data List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      // Reverse order to show newest on top
                      final item = history[history.length - 1 - index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.formattedTimestamp,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'pH ${item.ph.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: _buildMetric('Temp', '${item.temperature}°C', AppColors.temperature)),
                                Expanded(child: _buildMetric('Moist', '${item.moisture}%', AppColors.moisture)),
                                Expanded(child: _buildMetric('EC', '${item.conductivity}µS', AppColors.conductivity)),
                                Expanded(child: _buildMetric('NPK', '${item.nitrogen}-${item.phosphorus}-${item.potassium}', AppColors.fertility)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
