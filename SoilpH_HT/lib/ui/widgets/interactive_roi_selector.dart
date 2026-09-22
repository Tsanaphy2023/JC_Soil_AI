import 'package:flutter/material.dart';
import 'package:soil_ph_ht/core/constants/ph_colors.dart';
import 'package:soil_ph_ht/core/services/multi_color_space_service.dart';

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

/// ข้อมูลเกณฑ์เฉดสีตามคู่มือทางวิชาการ (Table 2.3 Ground Truth Calibration)
class AcademicPhTier {
  final String rangeLabel;
  final String thaiTitle;
  final Color color;
  final double minPh;
  final double maxPh;
  final String advice;

  const AcademicPhTier({
    required this.rangeLabel,
    required this.thaiTitle,
    required this.color,
    required this.minPh,
    required this.maxPh,
    required this.advice,
  });
}

const List<AcademicPhTier> academicPhTiers = [
  AcademicPhTier(
    rangeLabel: '< 4.5',
    thaiTitle: 'กรดจัดรุนแรง',
    color: Color(0xFFE63946),
    minPh: 0.0,
    maxPh: 4.49,
    advice: 'ดินกรดรุนแรง ธาตุ Al/Mn ละลายเป็นพิษ ใส่ปูนโดโลไมต์ 300-500 กก./ไร่',
  ),
  AcademicPhTier(
    rangeLabel: '4.5 - 5.2',
    thaiTitle: 'กรดจัด',
    color: Color(0xFFF4A261),
    minPh: 4.5,
    maxPh: 5.2,
    advice: 'ฟอสฟอรัสถูกตรึงสูง หว่านปูนมาร์ลหรือปูนขาวปรับสภาพดินก่อนให้ปุ๋ย',
  ),
  AcademicPhTier(
    rangeLabel: '5.3 - 6.0',
    thaiTitle: 'กรดปานกลาง',
    color: Color(0xFFE9C46A),
    minPh: 5.3,
    maxPh: 6.0,
    advice: 'เหมาะสมต่อสับปะรด ยางพารา ชา สำหรับทุเรียนควรเสริมอินทรียวัตถุ',
  ),
  AcademicPhTier(
    rangeLabel: '6.1 - 6.8',
    thaiTitle: 'กรดเล็กน้อย',
    color: Color(0xFFA7C957),
    minPh: 6.1,
    maxPh: 6.8,
    advice: 'ช่วงที่เหมาะสมที่สุดสำหรับทุเรียนและพืชส่วนใหญ่ ดูดซึม NPK สมบูรณ์',
  ),
  AcademicPhTier(
    rangeLabel: '6.9 - 7.5',
    thaiTitle: 'เป็นกลาง (เหมาะสม)',
    color: Color(0xFF2A9D8F),
    minPh: 6.9,
    maxPh: 7.5,
    advice: 'ค่าเป็นกลางสมดุล จุลินทรีย์ดินทำงานได้เต็มที่ ไม่จำเป็นต้องปรับค่า pH',
  ),
  AcademicPhTier(
    rangeLabel: '7.6 - 8.4',
    thaiTitle: 'ด่างปานกลาง',
    color: Color(0xFF457B9D),
    minPh: 7.6,
    maxPh: 8.4,
    advice: 'จุลธาตุ Fe, Zn, Cu ละลายยาก ควรฉีดพ่นจุลธาตุทางใบและเติมปุ๋ยหมัก',
  ),
  AcademicPhTier(
    rangeLabel: '> 8.4',
    thaiTitle: 'ด่างรุนแรง',
    color: Color(0xFF1D3557),
    minPh: 8.41,
    maxPh: 14.0,
    advice: 'ดินเค็มโซดิก เสี่ยงต่อโครงสร้างดินแน่นทึบ ต้องระบายน้ำล้างเกลือและใส่ยิปซัม',
  ),
];

class InteractiveRoiSelector extends StatefulWidget {
  final RoiShape currentShape;
  final Function(RoiShape) onShapeChanged;
  final Function(RoiData) onRoiUpdated;
  final Color activeColor;
  final double? livePh;
  final MultiColorMetric? liveColorMetric;
  final String? liveStatusLabel;

  const InteractiveRoiSelector({
    super.key,
    required this.currentShape,
    required this.onShapeChanged,
    required this.onRoiUpdated,
    this.activeColor = PhColors.neonCyan,
    this.livePh,
    this.liveColorMetric,
    this.liveStatusLabel,
  });

  @override
  State<InteractiveRoiSelector> createState() => _InteractiveRoiSelectorState();
}

class _InteractiveRoiSelectorState extends State<InteractiveRoiSelector> {
  Offset _center = const Offset(200, 260);
  double _rectWidth = 220;
  double _rectHeight = 220;
  double _radius = 110;
  final List<Offset> _polygonPoints = [];

  // สถานะเปิด/ปิดการ์ดคำอธิบายเกณฑ์เฉดสีตามคู่มือวิชาการ
  bool _isLegendOpen = false;

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
    widget.onRoiUpdated(RoiData(
      shape: widget.currentShape,
      center: _center,
      width: _rectWidth,
      height: _rectHeight,
      radius: _radius,
      polygonPoints: List<Offset>.from(_polygonPoints),
    ));
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
      _notifyUpdate();
    });
  }

  int? _getActiveTierIndex() {
    final ph = widget.livePh;
    if (ph == null) return null;
    for (int i = 0; i < academicPhTiers.length; i++) {
      final tier = academicPhTiers[i];
      if (ph >= tier.minPh && ph <= tier.maxPh) return i;
    }
    return ph < 4.5 ? 0 : academicPhTiers.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final activeTierIndex = _getActiveTierIndex();

    return Stack(
      children: [
        // 1. ชั้นตรวจจับการสัมผัสและวาดกรอบรูปทรง ROI
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

        // 2. แถบเมนูปรับขนาด รูปร่างของ detection พร้อมแถบเฉดสีตามเกณฑ์คู่มือทางวิชาการ
        Positioned(
          left: 12,
          top: 105,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // เมนูแท่งแนวตั้ง (Shape + Size + Academic Color Strip)
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F1D), // Deep Cyber Dark
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.activeColor.withValues(alpha: 0.6), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- ส่วนที่ 1: เลือกรูปร่าง ROI ---
                    _buildShapeBtn(
                      icon: Icons.crop_square_rounded,
                      shape: RoiShape.rectangle,
                      tooltip: 'กรอบสี่เหลี่ยม (Rectangle)',
                    ),
                    const SizedBox(height: 6),
                    _buildShapeBtn(
                      icon: Icons.circle_outlined,
                      shape: RoiShape.circle,
                      tooltip: 'กรอบวงกลม (Circle)',
                    ),
                    const SizedBox(height: 6),
                    _buildShapeBtn(
                      icon: Icons.polyline_rounded,
                      shape: RoiShape.polygon,
                      tooltip: 'โพลีกอนลากเส้นอิสระ (Polygon)',
                    ),

                    if (widget.currentShape == RoiShape.polygon && _polygonPoints.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFB300), size: 19),
                        tooltip: 'ล้างเส้นวาดใหม่',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _resetPolygon,
                      ),
                    ],

                    // --- ส่วนที่ 2: ปรับขนาดรูปร่าง ROI ---
                    if (widget.currentShape != RoiShape.polygon) ...[
                      const Divider(color: Colors.white24, height: 12),
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
                      const SizedBox(height: 2),
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
                    ],

                    // --- ส่วนที่ 3: แถบเฉดสีตามเกณฑ์คู่มือทางวิชาการ (Table 2.3) ---
                    const Divider(color: Colors.white24, height: 14),
                    Tooltip(
                      message: 'เกณฑ์เฉดสีมาตรฐานวิชาการ (ตารางที่ 2.3)',
                      child: InkWell(
                        onTap: () => setState(() => _isLegendOpen = !_isLegendOpen),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _isLegendOpen
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _isLegendOpen
                                ? Border.all(color: const Color(0xFF00E5FF), width: 1.2)
                                : null,
                          ),
                          child: const Icon(
                            Icons.palette_rounded,
                            size: 19,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // รายการแถบสี 7 ระดับมาตรฐานวิชาการ
                    for (int i = 0; i < academicPhTiers.length; i++) ...[
                      _buildColorSwatch(i, academicPhTiers[i], activeTierIndex == i),
                      if (i < academicPhTiers.length - 1) const SizedBox(height: 3.5),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. การ์ดเปิดแสดงรายละเอียดเกณฑ์เฉดสีตามคู่มือทางวิชาการแบบละเอียด (Expandable Legend Card)
              if (_isLegendOpen) _buildLegendCard(activeTierIndex),
            ],
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? widget.activeColor.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: widget.activeColor, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 20,
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
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
        child: Icon(icon, size: 19, color: widget.activeColor),
      ),
    );
  }

  Widget _buildColorSwatch(int index, AcademicPhTier tier, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() => _isLegendOpen = true);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 34 : 26,
            height: isActive ? 16 : 11,
            decoration: BoxDecoration(
              color: tier.color,
              borderRadius: BorderRadius.circular(isActive ? 4.5 : 2.5),
              border: Border.all(
                color: isActive ? Colors.white : Colors.black45,
                width: isActive ? 1.8 : 0.8,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: tier.color.withValues(alpha: 0.85),
                        blurRadius: 7,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isActive
                ? const Center(
                    child: Icon(Icons.check, size: 10, color: Colors.white),
                  )
                : null,
          ),

          // ตัวชี้ค่าการวิเคราะห์ขณะวิเคราะห์สด (Live Active Pointer Tag)
          if (isActive && widget.livePh != null && !_isLegendOpen)
            Positioned(
              left: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F1D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tier.color, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
                child: Text(
                  'pH ${widget.livePh!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(int? activeTierIndex) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF80A0F1D), // Dark Cyber Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.4), // RBRU Gold Border
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(2, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ส่วนหัวการ์ด พร้อมปุ่มปิด
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 16, color: Color(0xFFFFD700)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'เกณฑ์เฉดสีคู่มือวิชาการ',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isLegendOpen = false),
                child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'ตารางที่ 2.3 คู่มือฟิสิกส์เกษตร & กรมพัฒนาที่ดิน',
            style: TextStyle(fontSize: 9.5, color: Colors.white54),
          ),
          const Divider(color: Colors.white24, height: 12),

          // กล่องแสดงผลขณะตรวจวัดสด (Live Readout Box)
          if (widget.livePh != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: (activeTierIndex != null
                        ? academicPhTiers[activeTierIndex].color
                        : const Color(0xFF00E5FF))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activeTierIndex != null
                      ? academicPhTiers[activeTierIndex].color
                      : const Color(0xFF00E5FF),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.liveColorMetric != null
                          ? widget.liveColorMetric!.toColor
                          : (activeTierIndex != null
                              ? academicPhTiers[activeTierIndex].color
                              : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กำลังวิเคราะห์สด: pH ${widget.livePh!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (activeTierIndex != null)
                          Text(
                            '${academicPhTiers[activeTierIndex].thaiTitle} (${academicPhTiers[activeTierIndex].rangeLabel})',
                            style: TextStyle(
                              fontSize: 10,
                              color: academicPhTiers[activeTierIndex].color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (widget.liveColorMetric != null)
                          Text(
                            'CIE L*a*b*: (${widget.liveColorMetric!.labL.toStringAsFixed(1)}, ${widget.liveColorMetric!.labA.toStringAsFixed(1)}, ${widget.liveColorMetric!.labB.toStringAsFixed(1)})',
                            style: const TextStyle(fontSize: 8.5, color: Colors.white60),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // รายการเกณฑ์ 7 ระดับมาตรฐาน
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int idx = 0; idx < academicPhTiers.length; idx++) ...[
                    Builder(builder: (context) {
                      final tier = academicPhTiers[idx];
                      final bool isCur = activeTierIndex == idx;
                      return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCur ? tier.color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: isCur ? Border.all(color: tier.color, width: 1.3) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: tier.color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.white54, width: 0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${tier.rangeLabel}  ',
                                  style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Flexible(
                                  child: Text(
                                    tier.thaiTitle,
                                    style: TextStyle(fontSize: 9.0, color: tier.color, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCur) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: tier.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'วิเคราะห์ตรง',
                                      style: TextStyle(fontSize: 7.5, color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              tier.advice,
                              style: const TextStyle(fontSize: 8.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                    }),
                    if (idx < academicPhTiers.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
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
