import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';

class PhHistoryScreen extends StatelessWidget {
  const PhHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();
    final history = vm.historyLog;
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      backgroundColor: PhColors.background,
      appBar: AppBar(
        title: const Text('ประวัติการตรวจวัด & บันทึกชดเชย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: PhColors.neonGreen),
            tooltip: 'ส่งออก CSV',
            onPressed: vm.isExporting
                ? null
                : () async {
                    final path = await vm.exportCsv();
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ส่งออกไฟล์เรียบร้อย: $path'),
                          backgroundColor: PhColors.cardBg,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'ล้างประวัติ',
            onPressed: history.isEmpty
                ? null
                : () {
                    vm.clearHistory();
                  },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีข้อมูลการตรวจวัด\nข้อมูลจะถูกบันทึกอัตโนมัติเมื่อเซนเซอร์อ่านค่า',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = history[index];
                final phColor = PhColors.getColorForPh(item.phCalibrated);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'pH ${item.phCalibrated.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: phColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.deltaPhTotal > 0
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Δ ${item.deltaPhTotal > 0 ? '+' : ''}${item.deltaPhTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.deltaPhTotal > 0
                                          ? Colors.greenAccent
                                          : Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              timeFormat.format(item.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'ดิบ: ${item.rawReading.phRaw.toStringAsFixed(2)} pH',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'T: ${item.rawReading.temperature.toStringAsFixed(1)}°C',
                              style: const TextStyle(fontSize: 11, color: PhColors.neonAmber),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'H: ${item.rawReading.moisture.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: PhColors.neonCyan),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'EC: ${item.rawReading.conductivity}',
                              style: const TextStyle(fontSize: 11, color: PhColors.neonPurple),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.physicalInterpretation,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
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
}
