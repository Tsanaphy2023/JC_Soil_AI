import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/soil_reading.dart';
import '../../domain/models/agronomic_assessment.dart';
import '../../domain/models/soil_color_scale.dart';

class AgronomicSummarySheet extends StatelessWidget {
  final AgronomicAssessment assessment;
  final SoilReading? reading;

  const AgronomicSummarySheet({
    super.key,
    required this.assessment,
    this.reading,
  });

  static void show(BuildContext context, AgronomicAssessment assessment, {SoilReading? reading}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => AgronomicSummarySheet(assessment: assessment, reading: reading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.88;
    final soilReading = reading ?? SoilReading.initial();

    return DefaultTabController(
      length: 2,
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Color(0xFF14181F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ผลการวิเคราะห์สภาพดิน & คำแนะนำ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 3. Soil Health Summary Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: _buildHealthScoreHeader(soilReading),
              ),

              // 4. Modern Pill Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.green.shade800.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.8), width: 1.2),
                  ),
                  labelColor: Colors.greenAccent,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ข้อเสนอแนะ (${assessment.adviceList.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.palette_outlined, size: 16),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'แถบสีเคมี LDD/FAO',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Tab Views (Scrollable contents)
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Enhanced Actionable Recommendations
                    _buildRecommendationsTab(context, soilReading),

                    // Tab 2: Colorimetric Scales (No overflow)
                    _buildColorScalesTab(soilReading),
                  ],
                ),
              ),

              // 6. Bottom Action Bar
              _buildBottomActionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Composite Soil Health Header Card
  Widget _buildHealthScoreHeader(SoilReading reading) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: assessment.healthStatusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Health Score Circular Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: assessment.healthStatusColor.withValues(alpha: 0.2),
                  border: Border.all(color: assessment.healthStatusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${assessment.healthScore.toInt()}',
                    style: TextStyle(
                      color: assessment.healthStatusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Status Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: assessment.healthStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            assessment.healthStatusTitle,
                            style: TextStyle(
                              color: assessment.healthStatusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ดัชนีสุขภาพดินวิเคราะห์จาก pH, NPK, ความชื้น และ EC รวมกัน',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 4-Quadrant Quick Status Badges (Responsive)
          Row(
            children: [
              Expanded(
                child: _buildMiniMetricChip(
                  icon: Icons.water_drop,
                  label: 'ความชื้น',
                  value: '${reading.moisture.toStringAsFixed(1)}%',
                  status: reading.moisture < 35 ? 'แห้ง' : (reading.moisture <= 65 ? 'พอดี' : 'แฉะ'),
                  statusColor: reading.moisture < 35
                      ? Colors.amberAccent
                      : (reading.moisture <= 65 ? Colors.greenAccent : Colors.orangeAccent),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniMetricChip(
                  icon: Icons.bolt,
                  label: 'EC ความเค็ม',
                  value: '${reading.conductivity}',
                  status: reading.conductivity < 300 ? 'จืด' : (reading.conductivity <= 1200 ? 'พอดี' : 'เค็ม'),
                  statusColor: reading.conductivity <= 1200 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniMetricChip(
                  icon: Icons.science,
                  label: 'pH กรด-ด่าง',
                  value: reading.ph.toStringAsFixed(1),
                  status: reading.ph < 5.5 ? 'กรด' : (reading.ph <= 7.5 ? 'กลาง' : 'ด่าง'),
                  statusColor: reading.ph < 5.5
                      ? Colors.orangeAccent
                      : (reading.ph <= 7.5 ? Colors.greenAccent : Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniMetricChip(
                  icon: Icons.grass,
                  label: 'NPK รวม',
                  value: '${reading.nitrogen}-${reading.phosphorus}-${reading.potassium}',
                  status: (reading.nitrogen + reading.phosphorus + reading.potassium) < 100 ? 'ต่ำ' : 'ปานกลาง',
                  statusColor: (reading.nitrogen + reading.phosphorus + reading.potassium) < 100
                      ? Colors.amberAccent
                      : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Enhanced Actionable Recommendations View
  Widget _buildRecommendationsTab(BuildContext context, SoilReading reading) {
    final items = assessment.adviceList;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // Section intro
        const Row(
          children: [
            Icon(Icons.tips_and_updates, color: Colors.amberAccent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'มาตรการปฏิบัติและข้อเสนอแนะรายด้าน (Action Plan)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Advice cards list
        for (final item in items) ...[
          _buildAdviceCard(item),
          const SizedBox(height: 8),
        ],

        // Overall Synthesis Summary Card
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.summarize, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'สรุปภาพรวมทางปฐพีวิทยา (Agronomic Summary):',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                assessment.recommendation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceCard(AgronomicAdviceItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2430),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Priority Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.category,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: item.priorityColor.withValues(alpha: 0.6), width: 0.8),
                ),
                child: Text(
                  item.priorityLabel,
                  style: TextStyle(
                    color: item.priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Title
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),

          // Detail
          Text(
            item.detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Quantitative Action Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'ปริมาณ/วิธีปฏิบัติ: ${item.actionDose}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

  /// Tab 2: Colorimetric Visual Scales View (No Overflow Guaranteed)
  Widget _buildColorScalesTab(SoilReading reading) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        const Row(
          children: [
            Icon(Icons.palette_outlined, color: Colors.amberAccent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'เทียบเคียงชุดตรวจวิเคราะห์ดิน กรมพัฒนาที่ดิน (LDD & FAO)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'เปรียบเทียบค่าที่วัดได้กับเฉดสีปฏิกิริยาเคมีภาคสนามระดับแปลง',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        ),
        const SizedBox(height: 10),

        // 1. pH Scale Tile (ตารางที่ 2.3 มาตรฐาน 7 ระดับ)
        _buildColorScaleCard(
          paramName: '1. ความเป็นกรด-ด่างดิน (Soil pH)',
          testMethod: 'เกณฑ์มาตรฐานตารางที่ 2.3 (Universal Indicator 7 Tiers)',
          valueDisplay: '${reading.ph.toStringAsFixed(2)} pH',
          minLabel: '< 4.5',
          maxLabel: '> 8.4',
          metric: SoilColorScale.evaluatePh(reading.ph),
          gradientColors: const [
            Color(0xFFE63946), // < 4.5 กรดจัดรุนแรง
            Color(0xFFF4A261), // 4.5 - 5.2 กรดจัด
            Color(0xFFE9C46A), // 5.3 - 6.0 กรดปานกลาง
            Color(0xFFA7C957), // 6.1 - 6.8 กรดเล็กน้อย
            Color(0xFF2A9D8F), // 6.9 - 7.5 เป็นกลาง
            Color(0xFF457B9D), // 7.6 - 8.4 ด่างปานกลาง
            Color(0xFF1D3557), // > 8.4 ด่างรุนแรง
          ],
        ),
        const SizedBox(height: 10),

        // 2. Nitrogen Scale Tile (ตารางที่ 2.3 มาตรฐาน 5 ระดับ)
        _buildColorScaleCard(
          paramName: '2. ไนโตรเจนที่เป็นประโยชน์ (Available N)',
          testMethod: 'เกณฑ์มาตรฐานตารางที่ 2.3 (NO3-N Griess 5 Tiers)',
          valueDisplay: '${reading.nitrogen} mg/kg',
          minLabel: '< 10',
          maxLabel: '> 80',
          metric: SoilColorScale.evaluateNitrogen(reading.nitrogen),
          gradientColors: const [
            Color(0xFFFEFAE0), // < 10 ต่ำมาก
            Color(0xFFF4A261), // 10 - 25 ต่ำ
            Color(0xFFE76F51), // 26 - 50 ปานกลาง
            Color(0xFFD62828), // 51 - 80 สูง
            Color(0xFF7209B7), // > 80 สูงมาก
          ],
        ),
        const SizedBox(height: 10),

        // 3. Phosphorus Scale Tile (ตารางที่ 2.3 มาตรฐาน 5 ระดับ)
        _buildColorScaleCard(
          paramName: '3. ฟอสฟอรัสที่เป็นประโยชน์ (Available P)',
          testMethod: 'เกณฑ์มาตรฐานตารางที่ 2.3 (Bray II / Blue 5 Tiers)',
          valueDisplay: '${reading.phosphorus} mg/kg',
          minLabel: '< 5',
          maxLabel: '> 60',
          metric: SoilColorScale.evaluatePhosphorus(reading.phosphorus),
          gradientColors: const [
            Color(0xFFFAF0CA), // < 5 ต่ำมาก
            Color(0xFFA2D2FF), // 5 - 15 ต่ำ
            Color(0xFF3A86FF), // 16 - 30 ปานกลาง
            Color(0xFF003049), // 31 - 60 สูง
            Color(0xFF03045E), // > 60 สูงมาก
          ],
        ),
        const SizedBox(height: 10),

        // 4. Potassium Scale Tile (ตารางที่ 2.3 มาตรฐาน 5 ระดับ)
        _buildColorScaleCard(
          paramName: '4. โพแทสเซียมที่แลกเปลี่ยนได้ (Exchangeable K)',
          testMethod: 'เกณฑ์มาตรฐานตารางที่ 2.3 (Cobaltinitrite 5 Tiers)',
          valueDisplay: '${reading.potassium} mg/kg',
          minLabel: '< 40',
          maxLabel: '> 250',
          metric: SoilColorScale.evaluatePotassium(reading.potassium),
          gradientColors: const [
            Color(0xFFEDF2F4), // < 40 ต่ำมาก
            Color(0xFFFFD166), // 40 - 80 ต่ำ
            Color(0xFFF3722C), // 81 - 150 ปานกลาง
            Color(0xFFD90429), // 151 - 250 สูง
            Color(0xFF6A040F), // > 250 สูงมาก
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Clean Color Scale Card (Anti-Overflow Design)
  Widget _buildColorScaleCard({
    required String paramName,
    required String testMethod,
    required String valueDisplay,
    required String minLabel,
    required String maxLabel,
    required SoilColorMetric metric,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2430),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: metric.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Parameter name + Value Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  paramName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Value Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: metric.color.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: metric.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 0.8),
                      ),
                    ),
                    Text(
                      valueDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Row 2: Method and Level label
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  testMethod,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                metric.labelThai,
                style: TextStyle(
                  color: metric.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Continuous Gradient Bar with Position Pointer
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double pointerX = (width * metric.normalized).clamp(6.0, width - 10.0);

              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 9,
                        width: width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(colors: gradientColors),
                        ),
                      ),
                      Positioned(
                        left: pointerX - 6,
                        top: -3.5,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black87, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(minLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5)),
                      Text(maxLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5)),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),

          // Actionable advice note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amberAccent, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    metric.advice,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Quick Copy / Share Bar
  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF10141B),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                side: const BorderSide(color: Colors.greenAccent),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('คัดลอกข้อเสนอแนะ', style: TextStyle(fontSize: 12.5)),
              onPressed: () {
                final buffer = StringBuffer();
                buffer.writeln('📋 ผลวิเคราะห์ดินและข้อเสนอแนะ (JC Soil AI):');
                buffer.writeln('• สุขภาพดิน: ${assessment.healthStatusTitle} (คะแนน: ${assessment.healthScore.toInt()}/100)');
                buffer.writeln('• ${assessment.moistureMessage}');
                buffer.writeln('• ${assessment.salinityMessage}');
                buffer.writeln('• ${assessment.phMessage}');
                buffer.writeln('• ${assessment.npkSummary}');
                buffer.writeln('\n[มาตรการแนะนำ]:');
                for (final item in assessment.adviceList) {
                  buffer.writeln('▶ ${item.category} [${item.priorityLabel}]: ${item.title}');
                  buffer.writeln('  วิธีปฏิบัติ: ${item.actionDose}');
                }
                buffer.writeln('\nสรุป: ${assessment.recommendation}');

                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('คัดลอกข้อเสนอแนะและผลวิเคราะห์ลงคลิปบอร์ดแล้ว'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
