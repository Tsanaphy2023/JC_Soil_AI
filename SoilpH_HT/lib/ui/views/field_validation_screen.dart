import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/models/ai_training_sample.dart';
import '../../data/models/field_validation_record.dart';
import '../../data/models/ph_sensor_reading.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';

class FieldValidationScreen extends StatefulWidget {
  const FieldValidationScreen({super.key});

  @override
  State<FieldValidationScreen> createState() => _FieldValidationScreenState();
}

class _FieldValidationScreenState extends State<FieldValidationScreen> {
  // District presets for Chanthaburi and Trat
  static const List<String> chanthaburiDistricts = [
    'ท่าใหม่',
    'เขาคิชฌกูฏ',
    'ขลุง',
    'มะขาม',
    'เมืองจันทบุรี',
    'โป่งน้ำร้อน',
  ];

  static const List<String> tratDistricts = [
    'เขาสมิง',
    'บ่อไร่',
    'แหลมงอบ',
    'เมืองตราด',
    'คลองใหญ่',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();
    final stats = vm.benchmarkStats;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: PhColors.background,
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('ทดสอบภาคสนาม & สร้างชุดข้อมูล AI'),
          ),
          bottom: const TabBar(
            indicatorColor: PhColors.neonGreen,
            labelColor: PhColors.neonGreen,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.verified_outlined),
                text: 'ทดสอบสวนทุเรียน จันทบุรี/ตราด',
              ),
              Tab(
                icon: Icon(Icons.dataset_outlined),
                text: 'ชุดข้อมูลฝึก AI (E-T-pH)',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Durian Field Validation (Objective 3)
            _buildFieldValidationTab(context, vm, stats),
            // Tab 2: AI Training Dataset (Objective 1)
            _buildAiDatasetTab(context, vm),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: Durian Field Validation (Objective 3)
  // =========================================================================

  Widget _buildFieldValidationTab(
    BuildContext context,
    PhMonitorViewModel vm,
    BenchmarkStatistics stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Benchmark Statistical Summary Card
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
                          color: PhColors.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights,
                          color: PhColors.neonGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ดัชนีชี้วัดความแม่นยำเทียบเครื่องมือมาตรฐาน',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'สวนทุเรียน จ.จันทบุรี และ จ.ตราด (Standard Benchtop Ref)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Metrics Grid: RMSE, %Bias, R^2, Samples
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          label: 'AI RMSE',
                          val: '${stats.rmseAi.toStringAsFixed(3)} pH',
                          sub: 'Raw: ${stats.rmseRaw.toStringAsFixed(3)}',
                          color: PhColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statBox(
                          label: 'AI %Bias',
                          val: '${stats.meanBiasPercentAi.toStringAsFixed(2)}%',
                          sub: 'เกณฑ์ < 1.0%',
                          color: stats.meanBiasPercentAi < 1.0
                              ? PhColors.neonGreen
                              : PhColors.neonAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statBox(
                          label: 'R² Correlation',
                          val: stats.rSquaredAi.toStringAsFixed(4),
                          sub: 'Raw: ${stats.rSquaredRaw.toStringAsFixed(2)}',
                          color: PhColors.neonCyan,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // EURACHEM Acceptance Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: PhColors.neonGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PhColors.neonGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: PhColors.neonGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ผ่านเกณฑ์มาตรฐาน EURACHEM (%Bias < 1%): ${stats.passedEurachemCount}/${stats.sampleCount} จุดทดสอบ',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: PhColors.neonGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Add Record & Export CSV
          Row(
            children: [
              Expanded(
                flex: 6,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PhColors.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'บันทึกจุดทดสอบแปลง',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  onPressed: () => _showAddValidationDialog(context, vm),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PhColors.neonCyan),
                    foregroundColor: PhColors.neonCyan,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ส่งออก CSV',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  onPressed: () async {
                    final path = await vm.exportValidationCsv();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ส่งออกไฟล์เรียบร้อย: $path')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Records Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รายการจุดทดสอบแปลงทุเรียน (${vm.validationRecords.length} จุด)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Record Cards
          if (vm.validationRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีข้อมูลการทดสอบภาคสนาม',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...vm.validationRecords.map((rec) => _buildValidationCard(context, vm, rec)),
        ],
      ),
    );
  }

  Widget _buildValidationCard(
    BuildContext context,
    PhMonitorViewModel vm,
    FieldValidationRecord rec,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PhColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.province == 'จันทบุรี'
                      ? PhColors.neonGreen.withOpacity(0.15)
                      : PhColors.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rec.province} • ${rec.district}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rec.province == 'จันทบุรี'
                        ? PhColors.neonGreen
                        : PhColors.neonCyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.orchardName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                onPressed: () => vm.deleteValidationRecord(rec.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comparison Row
          Row(
            children: [
              Expanded(
                child: _dataPoint(
                  'มาตรฐาน Lab Ref',
                  '${rec.standardPhMeterReading.toStringAsFixed(2)} pH',
                  Colors.white,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  'ชุดพกพา (AI PINN)',
                  '${rec.portableAiPhReading.toStringAsFixed(2)} pH',
                  PhColors.neonGreen,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  'เซนเซอร์ดิบ (Raw)',
                  '${rec.portableRawPhReading.toStringAsFixed(2)} pH',
                  Colors.white60,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  '%Bias AI',
                  '${rec.biasPercentAi.toStringAsFixed(2)}%',
                  rec.meetsEurachemCriterion ? PhColors.neonGreen : PhColors.neonAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'T: ${rec.temperatureC}°C • H: ${rec.moisturePct}% • EC: ${rec.ecUsCm} µS/cm • E: ${rec.sensorVoltageMv} mV • ${rec.durianVariety}',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: AI Training Dataset Builder (Objective 1)
  // =========================================================================

  Widget _buildAiDatasetTab(BuildContext context, PhMonitorViewModel vm) {
    final raw = vm.rawReading;
    final result = vm.calibratedResult;
    final nernstSlope = SoilPhReading.nernstSlope(raw.temperature);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nernst Live Theory & Live Potential Card
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
                          color: PhColors.neonPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.electric_bolt,
                          color: PhColors.neonPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ความสัมพันธ์ศักย์ไฟฟ้า (E) - อุณหภูมิ (T)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Nernst Theoretical Equation: E = -S(T) * (pH - 7.0)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          label: 'ศักย์ไฟฟ้าเซนเซอร์ E',
                          val: '${result.sensorVoltageMv > 0 ? "+" : ""}${result.sensorVoltageMv.toStringAsFixed(1)} mV',
                          sub: 'ที่ pH ${raw.phRaw.toStringAsFixed(2)}',
                          color: PhColors.neonPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statBox(
                          label: 'อุณหภูมิสัมบูรณ์ T',
                          val: '${raw.temperature.toStringAsFixed(1)} °C',
                          sub: '${(273.15 + raw.temperature).toStringAsFixed(1)} K',
                          color: PhColors.neonAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statBox(
                          label: 'ความชัน Nernst S(T)',
                          val: nernstSlope.toStringAsFixed(2),
                          sub: 'mV / pH',
                          color: PhColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Quick Standard Buffer Capture Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'บันทึกจุดสอบเทียบสารละลายมาตรฐาน (NIST Standard Buffers)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'จุ่มโพรบในสารละลายบัฟเฟอร์มาตรฐานแล้วกดปุ่มเพื่อบันทึกคู่ข้อมูลสำหรับฝึกสอนโมเดล AI',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _bufferButton(
                        label: 'NIST pH 4.01',
                        color: Colors.redAccent,
                        onPressed: () {
                          final tempPh = AiTrainingSample.calculateNistBufferPh(4.01, raw.temperature);
                          vm.addAiTrainingSample(
                            sampleType: 'NIST บัฟเฟอร์ 4.01',
                            standardPh: tempPh,
                          );
                          _showToast(context, 'บันทึกจุดบัฟเฟอร์ pH $tempPh สำเร็จ');
                        },
                      ),
                      _bufferButton(
                        label: 'NIST pH 7.00',
                        color: Colors.greenAccent,
                        onPressed: () {
                          final tempPh = AiTrainingSample.calculateNistBufferPh(7.00, raw.temperature);
                          vm.addAiTrainingSample(
                            sampleType: 'NIST บัฟเฟอร์ 7.00',
                            standardPh: tempPh,
                          );
                          _showToast(context, 'บันทึกจุดบัฟเฟอร์ pH $tempPh สำเร็จ');
                        },
                      ),
                      _bufferButton(
                        label: 'NIST pH 10.01',
                        color: Colors.blueAccent,
                        onPressed: () {
                          final tempPh = AiTrainingSample.calculateNistBufferPh(10.01, raw.temperature);
                          vm.addAiTrainingSample(
                            sampleType: 'NIST บัฟเฟอร์ 10.01',
                            standardPh: tempPh,
                          );
                          _showToast(context, 'บันทึกจุดบัฟเฟอร์ pH $tempPh สำเร็จ');
                        },
                      ),
                      _bufferButton(
                        label: 'ดินแปลงทุเรียน',
                        color: PhColors.neonAmber,
                        onPressed: () => _showCustomSampleDialog(context, vm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action Button: Export AI Dataset CSV
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PhColors.neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text(
                'ส่งออกชุดข้อมูลฝึก AI (CSV Dataset)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final path = await vm.exportAiDatasetCsv();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ส่งออกชุดข้อมูล AI เรียบร้อย: $path')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Dataset Samples Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ชุดข้อมูลตัวอย่าง (${vm.aiTrainingSamples.length} ตัวอย่าง)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dataset Cards
          ...vm.aiTrainingSamples.map((s) => _buildAiSampleCard(context, vm, s)),
        ],
      ),
    );
  }

  Widget _buildAiSampleCard(
    BuildContext context,
    PhMonitorViewModel vm,
    AiTrainingSample s,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PhColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.sampleType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: PhColors.neonPurple,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                onPressed: () => vm.deleteAiSample(s.sampleId),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _dataPoint(
                  'ศักย์ไฟฟ้า E',
                  '${s.sensorVoltageMv > 0 ? "+" : ""}${s.sensorVoltageMv} mV',
                  Colors.white,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  'อุณหภูมิ T',
                  '${s.temperatureC} °C',
                  PhColors.neonAmber,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  'Standard pH',
                  s.standardPh.toStringAsFixed(2),
                  PhColors.neonGreen,
                ),
              ),
              Expanded(
                child: _dataPoint(
                  'Residual Non-linear',
                  '${s.residualMv > 0 ? "+" : ""}${s.residualMv} mV',
                  PhColors.neonCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Helpers & Dialogs
  // =========================================================================

  Widget _statBox({
    required String label,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PhColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PhColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _dataPoint(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _bufferButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddValidationDialog(BuildContext context, PhMonitorViewModel vm) {
    String selectedProvince = 'จันทบุรี';
    String selectedDistrict = chanthaburiDistricts.first;
    final orchardCtrl = TextEditingController(text: 'สวนทุเรียนหมอนทอง แปลงที่ 1');
    final standardPhCtrl = TextEditingController(text: vm.calibratedResult.phCalibrated.toStringAsFixed(2));
    String selectedVariety = 'หมอนทอง (Monthong)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final districts = selectedProvince == 'จันทบุรี'
              ? chanthaburiDistricts
              : tratDistricts;

          return AlertDialog(
            backgroundColor: PhColors.cardBg,
            title: const Text('บันทึกผลการทดสอบภาคสนาม', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Province Selection
                  Row(
                    children: [
                      const Text('จังหวัด: ', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('จันทบุรี'),
                        selected: selectedProvince == 'จันทบุรี',
                        onSelected: (_) {
                          setDialogState(() {
                            selectedProvince = 'จันทบุรี';
                            selectedDistrict = chanthaburiDistricts.first;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('ตราด'),
                        selected: selectedProvince == 'ตราด',
                        onSelected: (_) {
                          setDialogState(() {
                            selectedProvince = 'ตราด';
                            selectedDistrict = tratDistricts.first;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // District dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(labelText: 'อำเภอในแปลงปลูก'),
                    dropdownColor: PhColors.cardBg,
                    items: districts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedDistrict = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Orchard Name
                  TextField(
                    controller: orchardCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อสวน / เจ้าของแปลง'),
                  ),
                  const SizedBox(height: 10),

                  // Standard Meter pH input
                  TextField(
                    controller: standardPhCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'ค่าที่อ่านได้จากเครื่องวัดมาตรฐาน (Lab Benchtop)',
                      suffixText: 'pH',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Current portable kit readings info
                  Text(
                    'ค่าที่เครื่องพกพาอ่านได้ขณะนี้:\n• AI Calibrated: ${vm.calibratedResult.phCalibrated} pH\n• Raw Sensor: ${vm.rawReading.phRaw} pH\n• Temp: ${vm.rawReading.temperature} °C • H: ${vm.rawReading.moisture}%',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: PhColors.neonGreen, foregroundColor: Colors.black),
                onPressed: () {
                  final stdPh = double.tryParse(standardPhCtrl.text) ?? vm.calibratedResult.phCalibrated;
                  vm.addFieldValidationRecord(
                    province: selectedProvince,
                    district: selectedDistrict,
                    orchardName: orchardCtrl.text.trim(),
                    durianVariety: selectedVariety,
                    standardPh: stdPh,
                  );
                  Navigator.pop(ctx);
                  _showToast(context, 'บันทึกจุดทดสอบสวนทุเรียน $selectedDistrict สำเร็จ');
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomSampleDialog(BuildContext context, PhMonitorViewModel vm) {
    final nameCtrl = TextEditingController(text: 'ดินแปลงทุเรียน ท่าใหม่ ร่อง 2');
    final stdPhCtrl = TextEditingController(text: '5.60');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PhColors.cardBg,
        title: const Text('บันทึกดินตัวอย่างแปลงทุเรียน', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อตัวอย่างดิน / แหล่งที่มา'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stdPhCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'ค่า pH อ้างอิงจากแล็บ (Ground Truth pH)',
                suffixText: 'pH',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PhColors.neonGreen, foregroundColor: Colors.black),
            onPressed: () {
              final stdPh = double.tryParse(stdPhCtrl.text) ?? 5.60;
              vm.addAiTrainingSample(
                sampleType: nameCtrl.text.trim(),
                standardPh: stdPh,
              );
              Navigator.pop(ctx);
              _showToast(context, 'บันทึกชุดข้อมูล AI สำเร็จ');
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
