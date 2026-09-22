import 'package:flutter/material.dart';

enum RoiShape {
  rectangle,
  circle,
  polygon,
}

class RoiData {
  final RoiShape shape;
  final Offset center;
  final double width;
  final double height;
  final double radius;
  final List<Offset> polygonPoints;

  const RoiData({
    required this.shape,
    required this.center,
    required this.width,
    required this.height,
    required this.radius,
    required this.polygonPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'shape': shape.name,
      'centerX': center.dx,
      'centerY': center.dy,
      'width': width,
      'height': height,
      'radius': radius,
      'pointsCount': polygonPoints.length,
    };
  }
}

class InteractiveRoiSelector extends StatefulWidget {
  final RoiShape currentShape;
  final Function(RoiShape) onShapeChanged;
  final Function(RoiData) onRoiUpdated;
  final Color activeColor;

  const InteractiveRoiSelector({
    super.key,
    required this.currentShape,
    required this.onShapeChanged,
    required this.onRoiUpdated,
    this.activeColor = const Color(0xFF00E5FF), // Neon Cyan
  });

  @override
  State<InteractiveRoiSelector> createState() => _InteractiveRoiSelectorState();
}

class _InteractiveRoiSelectorState extends State<InteractiveRoiSelector> {
  // พิกัดกึ่งกลางและขนาดของกรอบสี่เหลี่ยม / วงกลม
  Offset _center = const Offset(200, 280);
  double _rectWidth = 220;
  double _rectHeight = 220;
  double _radius = 110;

  // รายการพิกัดจุดสำหรับโพลีกอนแบบลากเส้นอิสระ
  final List<Offset> _polygonPoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _center = Offset(size.width / 2, size.height * 0.40);
      });
      _notifyUpdate();
    });
  }

  void _notifyUpdate() {
    widget.onRoiUpdated(
      RoiData(
        shape: widget.currentShape,
        center: _center,
        width: _rectWidth,
        height: _rectHeight,
        radius: _radius,
        polygonPoints: List.unmodifiable(_polygonPoints),
      ),
    );
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
    _notifyUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // พื้นที่รับการสัมผัสและการวาดกรอบ
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) {
              if (widget.currentShape == RoiShape.polygon) {
                setState(() {
                  _polygonPoints.clear();
                  _polygonPoints.add(details.localPosition);
                });
              }
            },
            onPanUpdate: (details) {
              setState(() {
                if (widget.currentShape == RoiShape.polygon) {
                  _polygonPoints.add(details.localPosition);
                } else {
                  // เลื่อนตำแหน่งกึ่งกลางของกรอบสี่เหลี่ยมหรือวงกลม
                  _center += details.delta;
                }
              });
              _notifyUpdate();
            },
            onPanEnd: (_) {
              if (widget.currentShape == RoiShape.polygon && _polygonPoints.length >= 3) {
                setState(() {
                  _polygonPoints.add(_polygonPoints.first);
                });
              }
              _notifyUpdate();
            },
            child: CustomPaint(
              painter: _RoiCustomPainter(
                shape: widget.currentShape,
                center: _center,
                rectWidth: _rectWidth,
                rectHeight: _rectHeight,
                radius: _radius,
                polygonPoints: _polygonPoints,
                activeColor: widget.activeColor,
              ),
            ),
          ),
        ),

        // แถบเครื่องมือเลือกและปรับขนาดรูปทรง (Floating Toolbar)
        Positioned(
          left: 14,
          top: 110,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xE60A0F1D), // Deep Cyber Dark
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.activeColor.withValues(alpha: 0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShapeBtn(
                  icon: Icons.crop_square_rounded,
                  shape: RoiShape.rectangle,
                  tooltip: 'กรอบสี่เหลี่ยม (Rectangle)',
                ),
                const SizedBox(height: 8),
                _buildShapeBtn(
                  icon: Icons.circle_outlined,
                  shape: RoiShape.circle,
                  tooltip: 'กรอบวงกลม (Circle)',
                ),
                const SizedBox(height: 8),
                _buildShapeBtn(
                  icon: Icons.polyline_rounded,
                  shape: RoiShape.polygon,
                  tooltip: 'โพลีกอนลากเส้นอิสระ (Polygon)',
                ),
                if (widget.currentShape == RoiShape.polygon && _polygonPoints.isNotEmpty) ...[
                  const Divider(color: Colors.white24, height: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFB300), size: 20),
                    tooltip: 'ล้างเส้นวาดใหม่',
                    onPressed: _resetPolygon,
                  ),
                ],
                if (widget.currentShape != RoiShape.polygon) ...[
                  const Divider(color: Colors.white24, height: 16),
                  _buildSizeAdjuster(Icons.add_rounded, () {
                    setState(() {
                      if (widget.currentShape == RoiShape.circle) {
                        _radius = (_radius + 15).clamp(40, 250);
                      } else {
                        _rectWidth = (_rectWidth + 20).clamp(60, 380);
                        _rectHeight = (_rectHeight + 20).clamp(60, 380);
                      }
                      _notifyUpdate();
                    });
                  }),
                  _buildSizeAdjuster(Icons.remove_rounded, () {
                    setState(() {
                      if (widget.currentShape == RoiShape.circle) {
                        _radius = (_radius - 15).clamp(40, 250);
                      } else {
                        _rectWidth = (_rectWidth - 20).clamp(60, 380);
                        _rectHeight = (_rectHeight - 20).clamp(60, 380);
                      }
                      _notifyUpdate();
                    });
                  }),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShapeBtn({
    required IconData icon,
    required RoiShape shape,
    required String tooltip,
  }) {
    final bool isSelected = widget.currentShape == shape;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          widget.onShapeChanged(shape);
          _notifyUpdate();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? widget.activeColor.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: widget.activeColor, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? widget.activeColor : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeAdjuster(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Icon(icon, size: 20, color: widget.activeColor),
      ),
    );
  }
}

class _RoiCustomPainter extends CustomPainter {
  final RoiShape shape;
  final Offset center;
  final double rectWidth;
  final double rectHeight;
  final double radius;
  final List<Offset> polygonPoints;
  final Color activeColor;

  _RoiCustomPainter({
    required this.shape,
    required this.center,
    required this.rectWidth,
    required this.rectHeight,
    required this.radius,
    required this.polygonPoints,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (shape) {
      case RoiShape.rectangle:
        final rect = Rect.fromCenter(center: center, width: rectWidth, height: rectHeight);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);

        // Center reticle
        canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx + 14, center.dy), centerPaint);
        canvas.drawLine(Offset(center.dx, center.dy - 14), Offset(center.dx, center.dy + 14), centerPaint);
        break;

      case RoiShape.circle:
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, strokePaint);

        // Center reticle
        canvas.drawLine(Offset(center.dx - radius * 0.4, center.dy), Offset(center.dx + radius * 0.4, center.dy), centerPaint);
        canvas.drawLine(Offset(center.dx, center.dy - radius * 0.4), Offset(center.dx, center.dy + radius * 0.4), centerPaint);
        break;

      case RoiShape.polygon:
        if (polygonPoints.length > 1) {
          final path = Path();
          path.moveTo(polygonPoints.first.dx, polygonPoints.first.dy);
          for (int i = 1; i < polygonPoints.length; i++) {
            path.lineTo(polygonPoints[i].dx, polygonPoints[i].dy);
          }
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);

          // Draw vertex dots
          final dotPaint = Paint()..color = activeColor..style = PaintingStyle.fill;
          for (final pt in polygonPoints) {
            canvas.drawCircle(pt, 3.5, dotPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _RoiCustomPainter oldDelegate) => true;
}
