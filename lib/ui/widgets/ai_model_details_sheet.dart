import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/deep_learning_calibrator.dart';

class AiModelDetailsSheet extends StatelessWidget {
  final CalibratedSoilResult calibrationResult;
  final bool isAiActive;
  final ValueChanged<bool> onToggleAi;

  const AiModelDetailsSheet({
    super.key,
    required this.calibrationResult,
    required this.isAiActive,
    required this.onToggleAi,
  });

  static void show(
    BuildContext context, {
    required CalibratedSoilResult calibrationResult,
    required bool isAiActive,
    required ValueChanged<bool> onToggleAi,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => AiModelDetailsSheet(
        calibrationResult: calibrationResult,
        isAiActive: isAiActive,
        onToggleAi: onToggleAi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = calibrationResult.rawReading;
    final cal = calibrationResult.calibratedReading;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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

              // Title Header with Toggle Switch
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'JC Deep Learning Calibrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: isAiActive,
                    activeThumbColor: Colors.cyanAccent,
                    onChanged: (val) {
                      onToggleAi(val);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              'โมเดลโครงข่ายประสาทเทียมชดเชยค่าผิดพลาดของเซนเซอร์ (${calibrationResult.modelName})',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Divider(color: Colors.white24, height: 24),

            // AI Confidence & Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Inference Confidence',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${(calibrationResult.confidenceScore * 100).toStringAsFixed(1)}% (High Precision)',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAiActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAiActive ? 'ACTIVE' : 'BYPASS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'ตารางเปรียบเทียบค่าดิบ (Raw) กับค่าชดเชย AI (Calibrated)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Comparison Table
            _buildComparisonCard(
              title: 'ความชื้นดิน (Moisture)',
              raw: '${raw.moisture.toStringAsFixed(1)} %',
              cal: '${cal.moisture.toStringAsFixed(1)} %',
              delta: '${calibrationResult.moistureDelta > 0 ? '+' : ''}${calibrationResult.moistureDelta.toStringAsFixed(1)} %',
              color: AppColors.moisture,
              note: 'ชดเชยการลดลงของค่าไดอิเล็กทริกน้ำเมื่ออุณหภูมิเปลี่ยนแปลง',
            ),
            const SizedBox(height: 8),

            _buildComparisonCard(
              title: 'อุณหภูมิดิน (Temperature)',
              raw: '${raw.temperature.toStringAsFixed(1)} °C',
              cal: '${cal.temperature.toStringAsFixed(1)} °C',
              delta: '${calibrationResult.temperatureDelta > 0 ? '+' : ''}${calibrationResult.temperatureDelta.toStringAsFixed(1)} °C',
              color: AppColors.temperature,
              note: 'ชดเชยความเฉื่อยเชิงความร้อนและการนำความร้อนของแท่งโลหะ',
            ),
            const SizedBox(height: 8),

            _buildComparisonCard(
              title: 'การนำไฟฟ้า (EC)',
              raw: '${raw.conductivity} µS/cm',
              cal: '${cal.conductivity} µS/cm',
              delta: '${calibrationResult.ecDelta > 0 ? '+' : ''}${calibrationResult.ecDelta.toStringAsFixed(0)} µS',
              color: AppColors.conductivity,
              note: 'ปรับมาตรฐานอุณหภูมิอ้างอิง 25°C (Arrhenius Temperature Normalization)',
            ),

            const SizedBox(height: 14),

            // Technical Rationale Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔬 หลักการทางฟิสิกส์เกษตรและการเรียนรู้เชิงลึก (PINN Physics):',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${calibrationResult.compensationReason}\n'
                    '• โครงสร้างโมเดล: MLP Feedforward 5-Input → 8(LeakyReLU) → 6(GELU) → 4-Output\n'
                    '• สภาพแวดล้อม: Edge On-Device Real-time Inference (Latency < 2ms)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildComparisonCard({
    required String title,
    required String raw,
    required String cal,
    required String delta,
    required Color color,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Δ $delta',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Raw: $raw', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14, color: Colors.cyanAccent),
              ),
              Text(
                'AI Calibrated: $cal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
