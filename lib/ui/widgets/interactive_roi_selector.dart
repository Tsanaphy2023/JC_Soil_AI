import 'package:flutter/material.dart';

enum RoiShape {
  rectangle,
  circle,
  polygon,
}

class InteractiveRoiSelector extends StatefulWidget {
  final RoiShape currentShape;
  final Function(RoiShape) onShapeChanged;
  final Function(Map<String, dynamic>) onRoiUpdated;
  final bool isRecording;

  const InteractiveRoiSelector({
    super.key,
    required this.currentShape,
    required this.onShapeChanged,
    required this.onRoiUpdated,
    this.isRecording = false,
  });

  @override
  State<InteractiveRoiSelector> createState() => _InteractiveRoiSelectorState();
}

class _InteractiveRoiSelectorState extends State<InteractiveRoiSelector> {
  // Rectangle / Circle State (Center + Size)
  Offset _center = const Offset(200, 260);
  double _rectWidth = 220;
  double _rectHeight = 220;
  double _radius = 110;

  // Polygon Points (User Freehand / Tap to draw)
  final List<Offset> _polygonPoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _center = Offset(size.width / 2, size.height / 2 - 40);
        _notifyUpdate();
      });
    });
  }

  void _notifyUpdate() {
    widget.onRoiUpdated({
      'shape': widget.currentShape.name,
      'center': _center,
      'rectWidth': _rectWidth,
      'rectHeight': _rectHeight,
      'radius': _radius,
      'polygonPoints': List<Offset>.from(_polygonPoints),
    });
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
      _notifyUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isRecording ? Colors.redAccent : const Color(0xFF00E5FF);

    return Stack(
      children: [
        // Gesture Layer for Custom Painting & ROI Manipulation
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) {
              if (widget.currentShape == RoiShape.polygon) {
                setState(() {
                  _polygonPoints.add(details.localPosition);
                });
              }
            },
            onPanUpdate: (details) {
              if (widget.currentShape == RoiShape.polygon) {
                setState(() {
                  _polygonPoints.add(details.localPosition);
                });
              } else {
                setState(() {
                  _center += details.delta;
                });
              }
              _notifyUpdate();
            },
            onPanEnd: (details) {
              if (widget.currentShape == RoiShape.polygon) {
                setState(() {
                  // Close the loop if points >= 3
                  if (_polygonPoints.length >= 3) {
                    _polygonPoints.add(_polygonPoints.first);
                  }
                });
              }
              _notifyUpdate();
            },
            child: CustomPaint(
              painter: _RoiPainter(
                shape: widget.currentShape,
                center: _center,
                rectWidth: _rectWidth,
                rectHeight: _rectHeight,
                radius: _radius,
                polygonPoints: _polygonPoints,
                activeColor: activeColor,
              ),
            ),
          ),
        ),

        // Floating Shape Toolbar at Left
        Positioned(
          left: 16,
          top: 130,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xE00B132B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShapeButton(
                  icon: Icons.crop_square_rounded,
                  shape: RoiShape.rectangle,
                  tooltip: 'กรอบสี่เหลี่ยม (Rectangle)',
                  activeColor: activeColor,
                ),
                const SizedBox(height: 8),
                _buildShapeButton(
                  icon: Icons.circle_outlined,
                  shape: RoiShape.circle,
                  tooltip: 'กรอบวงกลม (Circle)',
                  activeColor: activeColor,
                ),
                const SizedBox(height: 8),
                _buildShapeButton(
                  icon: Icons.polyline_rounded,
                  shape: RoiShape.polygon,
                  tooltip: 'โพลีกอนลากเส้นอิสระ (Polygon)',
                  activeColor: activeColor,
                ),
                if (widget.currentShape == RoiShape.polygon && _polygonPoints.isNotEmpty) ...[
                  const Divider(color: Colors.white24, height: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.amberAccent, size: 20),
                    tooltip: 'ล้างเส้นวาดใหม่',
                    onPressed: _resetPolygon,
                  ),
                ],
                if (widget.currentShape != RoiShape.polygon) ...[
                  const Divider(color: Colors.white24, height: 16),
                  _buildSizeAdjuster(Icons.add, () {
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
                  _buildSizeAdjuster(Icons.remove, () {
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

  Widget _buildShapeButton({
    required IconData icon,
    required RoiShape shape,
    required String tooltip,
    required Color activeColor,
  }) {
    final isSelected = widget.currentShape == shape;
    return InkWell(
      onTap: () {
        widget.onShapeChanged(shape);
        _notifyUpdate();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? activeColor : Colors.white70,
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
        child: Icon(icon, size: 18, color: Colors.cyanAccent),
      ),
    );
  }
}

class _RoiPainter extends CustomPainter {
  final RoiShape shape;
  final Offset center;
  final double rectWidth;
  final double rectHeight;
  final double radius;
  final List<Offset> polygonPoints;
  final Color activeColor;

  _RoiPainter({
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

    final dashedPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (shape) {
      case RoiShape.rectangle:
        final rect = Rect.fromCenter(center: center, width: rectWidth, height: rectHeight);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);

        // Center reticle
        canvas.drawLine(Offset(center.dx - 12, center.dy), Offset(center.dx + 12, center.dy), dashedPaint);
        canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy + 12), dashedPaint);
        break;

      case RoiShape.circle:
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, strokePaint);

        // Crosshairs
        canvas.drawLine(Offset(center.dx - radius * 0.4, center.dy), Offset(center.dx + radius * 0.4, center.dy), dashedPaint);
        canvas.drawLine(Offset(center.dx, center.dy - radius * 0.4), Offset(center.dx, center.dy + radius * 0.4), dashedPaint);
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
  bool shouldRepaint(covariant _RoiPainter oldDelegate) => true;
}
