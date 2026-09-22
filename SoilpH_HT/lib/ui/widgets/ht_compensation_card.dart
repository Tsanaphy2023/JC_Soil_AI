import 'package:flutter/material.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/models/ph_sensor_reading.dart';

/// Deep Learning PINN H-T & Non-Linearity Error Compensation Breakdown Card
class HtCompensationCard extends StatelessWidget {
  final CalibratedPhResult result;
  final bool isAiActive;

  const HtCompensationCard({
    super.key,
    required this.result,
    required this.isAiActive,
  });

  @override
  Widget build(BuildContext context) {
    final raw = result.rawReading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PhColors.neonCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: PhColors.neonCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'การชดเชยค่าความคลาดเคลื่อน HT & Non-Linearity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Physics-Informed Neural Network (PINN)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Confidence Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: PhColors.neonGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PhColors.neonGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 13, color: PhColors.neonGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${(result.confidenceScore * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PhColors.neonGreen,
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

            // Sensor Voltage Banner (Objective 1)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PhColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PhColors.neonPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.electric_bolt, size: 16, color: PhColors.neonPurple),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ศักย์ไฟฟ้าเซนเซอร์ (Electrode Potential E):',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                  Text(
                    '${result.sensorVoltageMv > 0 ? '+' : ''}${result.sensorVoltageMv.toStringAsFixed(1)} mV',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: PhColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ),

            // Metrics Grid: Temperature, Moisture, EC
            Row(
              children: [
                // Temperature Box
                Expanded(
                  child: _MetricBox(
                    icon: Icons.thermostat,
                    iconColor: PhColors.neonAmber,
                    label: 'อุณหภูมิดิน (T)',
                    value: '${raw.temperature.toStringAsFixed(1)}°C',
                    deltaLabel: 'Temp: ${result.deltaPhTemperature > 0 ? '+' : ''}${result.deltaPhTemperature.toStringAsFixed(2)} pH',
                    deltaColor: result.deltaPhTemperature.abs() > 0.05
                        ? PhColors.neonAmber
                        : Colors.white60,
                  ),
                ),
                const SizedBox(width: 8),
                // Moisture Box
                Expanded(
                  child: _MetricBox(
                    icon: Icons.water_drop,
                    iconColor: PhColors.neonCyan,
                    label: 'ความชื้นดิน (H)',
                    value: '${raw.moisture.toStringAsFixed(1)}%',
                    deltaLabel: 'Imped: ${result.deltaPhMoisture > 0 ? '+' : ''}${result.deltaPhMoisture.toStringAsFixed(2)} pH',
                    deltaColor: result.deltaPhMoisture.abs() > 0.05
                        ? PhColors.neonCyan
                        : Colors.white60,
                  ),
                ),
                const SizedBox(width: 8),
                // EC Box
                Expanded(
                  child: _MetricBox(
                    icon: Icons.bolt,
                    iconColor: PhColors.neonPurple,
                    label: 'สภาพนำไฟฟ้า (EC)',
                    value: '${raw.conductivity}',
                    deltaLabel: 'µS/cm',
                    deltaColor: Colors.white60,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Objective 2: Decoupled Compensation Breakdown & Ablation Comparison
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PhColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PhColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'การแจกแจงค่าชดเชย AI (Error Decoupling Breakdown)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _decoupleChip(
                        '1. ผลของอุณหภูมิ (Temp Effect)',
                        '${result.deltaPhTemperature > 0 ? '+' : ''}${result.deltaPhTemperature.toStringAsFixed(2)}',
                        PhColors.neonAmber,
                      ),
                      _decoupleChip(
                        '2. ความไม่เป็นเชิงเส้น (Non-Linearity)',
                        '${result.deltaPhNonLinear > 0 ? '+' : ''}${result.deltaPhNonLinear.toStringAsFixed(2)}',
                        PhColors.neonCyan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _decoupleChip(
                        '3. รอยต่อดินแห้ง/น้ำขัง (Matrix H)',
                        '${result.deltaPhMoisture > 0 ? '+' : ''}${result.deltaPhMoisture.toStringAsFixed(2)}',
                        Colors.blueAccent,
                      ),
                      _decoupleChip(
                        'รวมชดเชยทั้งระบบ (ΔpH Total)',
                        '${result.deltaPhTotal > 0 ? '+' : ''}${result.deltaPhTotal.toStringAsFixed(2)}',
                        PhColors.neonGreen,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Comparison of Conventional ATC vs AI PINN
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'เทียบ Conventional ATC: ${result.atcPh.toStringAsFixed(2)} pH  •  AI PINN: ${result.phCalibrated.toStringAsFixed(2)} pH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Explainable AI (XAI) Interpretation Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PhColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PhColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 16, color: PhColors.neonCyan),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'การวิเคราะห์ทางกายภาพ (Physics Diagnostics)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.physicalInterpretation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isAiActive ? Colors.white : Colors.white60,
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

  Widget _decoupleChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: PhColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.white60),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String deltaLabel;
  final Color deltaColor;

  const _MetricBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.deltaLabel,
    required this.deltaColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: PhColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PhColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            deltaLabel,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: deltaColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
