import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AgronomicSummarySheet(assessment: assessment, reading: reading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row with Auto-scaling and Close button
              Row(
                children: [
                  const Icon(Icons.eco, color: Colors.greenAccent, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'ผลการวิเคราะห์สภาพดิน (Soil Diagnostics)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              const Divider(color: Colors.white24, height: 18),

              _buildRow('ความชื้น (Moisture):', assessment.moistureMessage, Icons.water_drop),
              _buildRow('ความเค็ม/การนำไฟฟ้า (EC):', assessment.salinityMessage, Icons.flash_on),
              _buildRow('ความเป็นกรด-ด่าง (pH):', assessment.phMessage, Icons.science),
              _buildRow('ธาตุอาหารหลัก (NPK):', assessment.npkSummary, Icons.grass),

              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คำแนะนำทางปฐพีวิทยา (Agronomic Action):',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assessment.recommendation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------------
              // Colorimetric Visual Scales (LDD & FAO Standards)
              // -------------------------------------------------------------
              if (reading != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.palette_outlined, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'แถบสีเคมีวิเคราะห์ดิน (Field Colorimetric Scale)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'เทียบเคียงแถบสีชุดตรวจวิเคราะห์ดิน กรมพัฒนาที่ดิน (LDD) และมาตรฐาน FAO',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                ),
                const SizedBox(height: 10),

                // pH Color Tile
                _buildColorScaleTile(
                  title: 'Soil pH (Universal Indicator)',
                  valueStr: '${reading!.ph.toStringAsFixed(2)} pH',
                  metric: SoilColorScale.evaluatePh(reading!.ph),
                  gradientColors: const [
                    Color(0xFFD32F2F), // <4.0
                    Color(0xFFFB8C00), // 5.0
                    Color(0xFFC0CA33), // 6.0
                    Color(0xFF43A047), // 7.0
                    Color(0xFF0288D1), // 8.0
                    Color(0xFF5E35B1), // >8.5
                  ],
                ),

                // Nitrogen Color Tile
                _buildColorScaleTile(
                  title: 'Available N (Griess Reaction)',
                  valueStr: '${reading!.nitrogen} mg/kg',
                  metric: SoilColorScale.evaluateNitrogen(reading!.nitrogen),
                  gradientColors: const [
                    Color(0xFFFFCDD2),
                    Color(0xFFF06292),
                    Color(0xFFE91E63),
                    Color(0xFFC2185B),
                    Color(0xFF880E4F),
                  ],
                ),

                // Phosphorus Color Tile
                _buildColorScaleTile(
                  title: 'Available P (Molybdenum Blue)',
                  valueStr: '${reading!.phosphorus} mg/kg',
                  metric: SoilColorScale.evaluatePhosphorus(reading!.phosphorus),
                  gradientColors: const [
                    Color(0xFFE1F5FE),
                    Color(0xFF4FC3F7),
                    Color(0xFF0288D1),
                    Color(0xFF1565C0),
                    Color(0xFF0D47A1),
                  ],
                ),

                // Potassium Color Tile
                _buildColorScaleTile(
                  title: 'Available K (Cobaltinitrite Turbidity)',
                  valueStr: '${reading!.potassium} mg/kg',
                  metric: SoilColorScale.evaluatePotassium(reading!.potassium),
                  gradientColors: const [
                    Color(0xFFFFF9C4),
                    Color(0xFFFFD54F),
                    Color(0xFFFFB300),
                    Color(0xFFFB8C00),
                    Color(0xFFE65100),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorScaleTile({
    required String title,
    required String valueStr,
    required SoilColorMetric metric,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Title + Color Chip Badge + Numeric Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: metric.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 0.8),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    metric.labelThai,
                    style: TextStyle(
                      color: metric.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($valueStr)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Continuous Gradient Color Scale with Current Pointer
          LayoutBuilder(
            builder: (context, box) {
              final double width = box.maxWidth;
              final double pointerX = (width * metric.normalized).clamp(4.0, width - 8.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient Bar
                  Container(
                    height: 8,
                    width: width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                  ),
                  // Pointer Dot
                  Positioned(
                    left: pointerX - 5,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black87, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 5),

          // Advice Text
          Text(
            metric.advice,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
