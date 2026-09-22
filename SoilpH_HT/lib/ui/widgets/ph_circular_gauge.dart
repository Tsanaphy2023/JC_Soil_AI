import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/ph_colors.dart';

/// High-Precision Circular pH Dial Gauge with Dynamic Glow
class PhCircularGauge extends StatelessWidget {
  final double currentPh;
  final double rawPh;
  final bool isAiActive;
  final double deltaPh;

  const PhCircularGauge({
    super.key,
    required this.currentPh,
    required this.rawPh,
    required this.isAiActive,
    required this.deltaPh,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = PhColors.getColorForPh(currentPh);
    final statusLabel = PhColors.getLabelForPh(currentPh);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PhColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Dial with Custom Painter (Auto-scaling based on available width)
          LayoutBuilder(
            builder: (context, constraints) {
              final dialSize = (constraints.maxWidth * 0.68).clamp(170.0, 240.0);
              return SizedBox(
                width: dialSize,
                height: dialSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(dialSize, dialSize),
                      painter: _PhDialPainter(
                        phValue: currentPh,
                        activeColor: statusColor,
                      ),
                    ),
                    // Center Readout
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPh.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: (dialSize * 0.22).clamp(32.0, 48.0),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'pH (PINN)',
                          style: TextStyle(
                            fontSize: (dialSize * 0.055).clamp(10.0, 13.0),
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isAiActive && deltaPh.abs() > 0.01) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: deltaPh > 0
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: deltaPh > 0 ? Colors.green : Colors.orange,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${deltaPh > 0 ? '+' : ''}${deltaPh.toStringAsFixed(2)} pH (PINN)',
                              style: TextStyle(
                                fontSize: (dialSize * 0.048).clamp(9.0, 11.0),
                                fontWeight: FontWeight.bold,
                                color: deltaPh > 0 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Status Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (isAiActive) ...[
            const SizedBox(height: 8),
            Text(
              'เซนเซอร์ดิบ: ${rawPh.toStringAsFixed(2)} pH • ชดเชยโดย PINN Edge AI',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhDialPainter extends CustomPainter {
  final double phValue;
  final Color activeColor;

  _PhDialPainter({required this.phValue, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 135.0 * (pi / 180.0);
    const sweepAngle = 270.0 * (pi / 180.0);

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Colored Arc based on pH Range (3.0 to 10.0)
    final clampedPh = phValue.clamp(3.0, 10.0);
    final normalized = (clampedPh - 3.0) / 7.0; // 0.0 to 1.0
    final activeSweep = sweepAngle * normalized;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Tick marks for pH 3, 4, 5, 6, 7, 8, 9, 10
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5;

    for (int p = 3; p <= 10; p++) {
      final tNorm = (p - 3.0) / 7.0;
      final angle = startAngle + (sweepAngle * tNorm);
      final tickStart = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius + 12) * cos(angle),
        center.dy + (radius + 12) * sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }

    // Pointer Dot
    final dotAngle = startAngle + activeSweep;
    final dotPos = Offset(
      center.dx + radius * cos(dotAngle),
      center.dy + radius * sin(dotAngle),
    );
    final dotGlow = Paint()
      ..color = activeColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(dotPos, 12, dotGlow);

    final dotWhite = Paint()..color = Colors.white;
    canvas.drawCircle(dotPos, 6, dotWhite);
  }

  @override
  bool shouldRepaint(covariant _PhDialPainter oldDelegate) {
    return oldDelegate.phValue != phValue || oldDelegate.activeColor != activeColor;
  }
}
