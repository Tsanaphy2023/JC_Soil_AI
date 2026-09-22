import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../domain/models/lime_prescription.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';
import '../widgets/nutrient_availability_chart.dart';

class PhAnalyticsScreen extends StatelessWidget {
  const PhAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();
    final prescription = vm.limePrescription;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: PhColors.background,
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('การวิเคราะห์ปฐพีวิทยา & ธาตุอาหาร'),
          ),
          bottom: const TabBar(
            indicatorColor: PhColors.neonGreen,
            labelColor: PhColors.neonGreen,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.eco), text: 'ธาตุอาหาร 10 ชนิด'),
              Tab(icon: Icon(Icons.architecture), text: 'ใบสั่งปูนปรับสภาพดิน'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Nutrient Bioavailability Chart
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  NutrientAvailabilityChart(
                    nutrients: vm.nutrients,
                    currentPh: vm.displayPh,
                  ),
                ],
              ),
            ),

            // Tab 2: Lime & Soil Amendment Prescription
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PhColors.neonAmber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.layers,
                                  color: PhColors.neonAmber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'เลือกเนื้อดินแปลงปลูก (Soil Texture)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Texture Selection Chips
                          Wrap(
                            spacing: 8,
                            children: SoilTexture.values.map((texture) {
                              final isSelected = vm.selectedTexture == texture;
                              return ChoiceChip(
                                label: Text(texture.label),
                                selected: isSelected,
                                selectedColor: PhColors.neonGreen.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? PhColors.neonGreen : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => vm.setSoilTexture(texture),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Prescription Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'ใบสั่งสูตรปรับปรุงดินเฉพาะแปลง',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: prescription.isAdjustmentNeeded
                                      ? PhColors.neonAmber.withOpacity(0.2)
                                      : PhColors.neonGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  prescription.isAdjustmentNeeded ? 'ต้องปรับสภาพ' : 'สมดุลแล้ว',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: prescription.isAdjustmentNeeded
                                        ? PhColors.neonAmber
                                        : PhColors.neonGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          if (prescription.dolomiteKgPerRai > 0) ...[
                            _DosageRow(
                              materialName: 'ปูนโดโลไมต์ (Dolomite)',
                              subtext: 'CaMg(CO3)2 เสริมแคลเซียมและแมกนีเซียม',
                              amount: '${prescription.dolomiteKgPerRai.toStringAsFixed(0)} กก./ไร่',
                              color: PhColors.neonGreen,
                            ),
                            const SizedBox(height: 12),
                            _DosageRow(
                              materialName: 'หรือ ปูนขาวเกษตร (Agricultural Lime)',
                              subtext: 'CaCO3 เพิ่ม pH รวดเร็ว',
                              amount: '${prescription.agriculturalLimeKgPerRai.toStringAsFixed(0)} กก./ไร่',
                              color: PhColors.neonCyan,
                            ),
                          ] else if (prescription.gypsumKgPerRai > 0) ...[
                            _DosageRow(
                              materialName: 'ยิปซัมเกษตร (Agricultural Gypsum)',
                              subtext: 'CaSO4.2H2O ลดด่างและแก้ดินเค็มโซดิก',
                              amount: '${prescription.gypsumKgPerRai.toStringAsFixed(0)} กก./ไร่',
                              color: PhColors.neonAmber,
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PhColors.neonGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: PhColors.neonGreen.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: PhColors.neonGreen),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ดินอยู่ในระดับ pH สมบูรณ์แบบ ไม่จำเป็นต้องใส่ปูนหรือสารลดด่าง',
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          const Text(
                            'แนวทางปฏิบัติการใส่ปูน (Application Steps)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prescription.applicationGuideline,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DosageRow extends StatelessWidget {
  final String materialName;
  final String subtext;
  final String amount;
  final Color color;

  const _DosageRow({
    required this.materialName,
    required this.subtext,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materialName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
