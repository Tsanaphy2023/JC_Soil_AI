import 'package:flutter/material.dart';
import 'package:soil_app/data/services/multi_color_space_service.dart';

enum RoiShape {
  rectangle,
  circle,
  polygon,
}

enum AcademicScaleType {
  ph,
  nitrogen,
  phosphorus,
  potassium,
}

class AcademicTierItem {
  final String rangeLabel;
  final String thaiTitle;
  final Color color;
  final double minVal;
  final double maxVal;
  final String advice;

  const AcademicTierItem({
    required this.rangeLabel,
    required this.thaiTitle,
    required this.color,
    required this.minVal,
    required this.maxVal,
    required this.advice,
  });
}

class InteractiveRoiSelector extends StatefulWidget {
  final RoiShape currentShape;
  final Function(RoiShape) onShapeChanged;
  final Function(Map<String, dynamic>) onRoiUpdated;
  final bool isRecording;
  final double? livePh;
  final double? liveSom;
  final int? liveNitrogen;
  final int? livePhosphorus;
  final int? livePotassium;
  final MultiColorMetric? liveColorMetric;
  final String? liveStatusLabel;

  const InteractiveRoiSelector({
    super.key,
    required this.currentShape,
    required this.onShapeChanged,
    required this.onRoiUpdated,
    this.isRecording = false,
    this.livePh,
    this.liveSom,
    this.liveNitrogen,
    this.livePhosphorus,
    this.livePotassium,
    this.liveColorMetric,
    this.liveStatusLabel,
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

  // สถานะเปิด/ปิดการ์ดคำอธิบายเกณฑ์เฉดสีตามคู่มือวิชาการ และประเภทพารามิเตอร์ที่เลือก
  bool _isLegendOpen = false;
  AcademicScaleType _selectedScale = AcademicScaleType.ph;

  static const List<AcademicTierItem> _phTiers = [
    AcademicTierItem(
      rangeLabel: '< 4.5',
      thaiTitle: 'กรดจัดรุนแรง',
      color: Color(0xFFE63946),
      minVal: 0.0,
      maxVal: 4.49,
      advice: 'ดินกรดรุนแรง ธาตุ Al/Mn ละลายเป็นพิษ ควรใส่ปูนโดโลไมต์ 300-500 กก./ไร่',
    ),
    AcademicTierItem(
      rangeLabel: '4.5 - 5.2',
      thaiTitle: 'กรดจัด',
      color: Color(0xFFF4A261),
      minVal: 4.5,
      maxVal: 5.2,
      advice: 'ฟอสฟอรัสถูกตรึงสูง หว่านปูนมาร์ลหรือปูนขาวปรับสภาพดินก่อนให้ปุ๋ย',
    ),
    AcademicTierItem(
      rangeLabel: '5.3 - 6.0',
      thaiTitle: 'กรดปานกลาง',
      color: Color(0xFFE9C46A),
      minVal: 5.3,
      maxVal: 6.0,
      advice: 'เหมาะสมต่อสับปะรด ยางพารา ชา สำหรับทุเรียนควรเสริมอินทรียวัตถุ',
    ),
    AcademicTierItem(
      rangeLabel: '6.1 - 6.8',
      thaiTitle: 'กรดเล็กน้อย',
      color: Color(0xFFA7C957),
      minVal: 6.1,
      maxVal: 6.8,
      advice: 'ช่วงที่เหมาะสมที่สุดสำหรับทุเรียนและพืชส่วนใหญ่ ดูดซึม NPK สมบูรณ์',
    ),
    AcademicTierItem(
      rangeLabel: '6.9 - 7.5',
      thaiTitle: 'เป็นกลาง (เหมาะสม)',
      color: Color(0xFF2A9D8F),
      minVal: 6.9,
      maxVal: 7.5,
      advice: 'ค่าเป็นกลางสมดุล จุลินทรีย์ดินทำงานได้เต็มที่ ไม่จำเป็นต้องปรับค่า pH',
    ),
    AcademicTierItem(
      rangeLabel: '7.6 - 8.4',
      thaiTitle: 'ด่างปานกลาง',
      color: Color(0xFF457B9D),
      minVal: 7.6,
      maxVal: 8.4,
      advice: 'จุลธาตุ Fe, Zn, Cu ละลายยาก ควรฉีดพ่นจุลธาตุทางใบและเติมปุ๋ยหมัก',
    ),
    AcademicTierItem(
      rangeLabel: '> 8.4',
      thaiTitle: 'ด่างรุนแรง',
      color: Color(0xFF1D3557),
      minVal: 8.41,
      maxVal: 14.0,
      advice: 'ดินเค็มโซดิก เสี่ยงต่อโครงสร้างดินแน่นทึบ ต้องระบายน้ำล้างเกลือและใส่ยิปซัม',
    ),
  ];

  static const List<AcademicTierItem> _nitrogenTiers = [
    AcademicTierItem(
      rangeLabel: '< 10',
      thaiTitle: 'ต่ำมาก',
      color: Color(0xFFFEFAE0),
      minVal: 0.0,
      maxVal: 9.9,
      advice: 'ขาดไนโตรเจนรุนแรง พืชชะงักการเจริญเติบโต ใบเหลือง ควรใส่ปุ๋ยยูเรียหรือปุ๋ยคอก',
    ),
    AcademicTierItem(
      rangeLabel: '10 - 25',
      thaiTitle: 'ต่ำ',
      color: Color(0xFFF4A261),
      minVal: 10.0,
      maxVal: 25.0,
      advice: 'ไนโตรเจนค่อนข้างต่ำ ควรเสริมปุ๋ยอินทรีย์บำรุงต้นระยะเจริญเติบโต',
    ),
    AcademicTierItem(
      rangeLabel: '26 - 50',
      thaiTitle: 'ปานกลาง (เหมาะสม)',
      color: Color(0xFFE76F51),
      minVal: 26.0,
      maxVal: 50.0,
      advice: 'ระดับสมดุลเหมาะสมต่อการเจริญเติบโตของลำต้นและใบ',
    ),
    AcademicTierItem(
      rangeLabel: '51 - 80',
      thaiTitle: 'สูง',
      color: Color(0xFFD62828),
      minVal: 51.0,
      maxVal: 80.0,
      advice: 'ไนโตรเจนสูงเพียงพอ ไม่จำเป็นต้องใส่ปุ๋ยเร่งใบเพิ่มในระยะนี้',
    ),
    AcademicTierItem(
      rangeLabel: '> 80',
      thaiTitle: 'สูงมาก',
      color: Color(0xFF7209B7),
      minVal: 80.1,
      maxVal: 999.0,
      advice: 'ไนโตรเจนสะสมเกิน เสี่ยงต่อการบ้าใบและโรคแมลง ควรงดปุ๋ยเคมีสูตรไนโตรเจนสูง',
    ),
  ];

  static const List<AcademicTierItem> _phosphorusTiers = [
    AcademicTierItem(
      rangeLabel: '< 5',
      thaiTitle: 'ต่ำมาก',
      color: Color(0xFFFAF0CA),
      minVal: 0.0,
      maxVal: 4.9,
      advice: 'ขาดฟอสฟอรัสรุนแรง รากพืชแคระแกร็น ไม่ออกดอก ควรเสริมปุ๋ยฟอสเฟต',
    ),
    AcademicTierItem(
      rangeLabel: '5 - 15',
      thaiTitle: 'ต่ำ',
      color: Color(0xFFA2D2FF),
      minVal: 5.0,
      maxVal: 15.0,
      advice: 'ฟอสฟอรัสต่ำ ควรใส่ปุ๋ย 16-20-0 หรือปุ๋ยหมักรองก้นหลุมเพื่อกระตุ้นราก',
    ),
    AcademicTierItem(
      rangeLabel: '16 - 30',
      thaiTitle: 'ปานกลาง (เหมาะสม)',
      color: Color(0xFF3A86FF),
      minVal: 16.0,
      maxVal: 30.0,
      advice: 'ระดับเหมาะสมต่อการพัฒนาระบบราก การแตกตาดอก และการติดผล',
    ),
    AcademicTierItem(
      rangeLabel: '31 - 60',
      thaiTitle: 'สูง',
      color: Color(0xFF003049),
      minVal: 31.0,
      maxVal: 60.0,
      advice: 'ฟอสฟอรัสสะสมสมบูรณ์เพียงพอ ชะลอการให้ปุ๋ยกลุ่มฟอสเฟต',
    ),
    AcademicTierItem(
      rangeLabel: '> 60',
      thaiTitle: 'สูงมาก',
      color: Color(0xFF03045E),
      minVal: 60.1,
      maxVal: 999.0,
      advice: 'ฟอสฟอรัสสูงเกินไป อาจขัดขวางการดูดซึมจุลธาตุสังกะสีและเหล็ก',
    ),
  ];

  static const List<AcademicTierItem> _potassiumTiers = [
    AcademicTierItem(
      rangeLabel: '< 40',
      thaiTitle: 'ต่ำมาก',
      color: Color(0xFFEDF2F4),
      minVal: 0.0,
      maxVal: 39.9,
      advice: 'ขาดโพแทสเซียม ขอบใบไหม้ ลำต้นล้มง่าย ผลผลิตรสชาติจืด ควรใส่ปุ๋ย 0-0-60',
    ),
    AcademicTierItem(
      rangeLabel: '40 - 80',
      thaiTitle: 'ต่ำ',
      color: Color(0xFFFFD166),
      minVal: 40.0,
      maxVal: 80.0,
      advice: 'โพแทสเซียมต่ำ ควรบำรุงด้วยปุ๋ยโพแทสเซียมหรือขี้เถ้าถ่านก่อนช่วงติดผล',
    ),
    AcademicTierItem(
      rangeLabel: '81 - 150',
      thaiTitle: 'ปานกลาง (เหมาะสม)',
      color: Color(0xFFF3722C),
      minVal: 81.0,
      maxVal: 150.0,
      advice: 'ระดับเหมาะสม สำหรับการสร้างเนื้อแป้ง น้ำตาล และคุณภาพผลผลิต',
    ),
    AcademicTierItem(
      rangeLabel: '151 - 250',
      thaiTitle: 'สูง',
      color: Color(0xFFD90429),
      minVal: 151.0,
      maxVal: 250.0,
      advice: 'โพแทสเซียมสะสมสูง ช่วยให้พืชทนแล้งและเนื้อผลแน่น ชะลอการให้ปุ๋ย K',
    ),
    AcademicTierItem(
      rangeLabel: '> 250',
      thaiTitle: 'สูงมาก',
      color: Color(0xFF6A040F),
      minVal: 250.1,
      maxVal: 999.0,
      advice: 'โพแทสเซียมสูงเกิน อาจรบกวนการดูดซึมแคลเซียมและแมกนีเซียม ทำให้ผลแตก',
    ),
  ];

  List<AcademicTierItem> get _currentTiers {
    switch (_selectedScale) {
      case AcademicScaleType.ph:
        return _phTiers;
      case AcademicScaleType.nitrogen:
        return _nitrogenTiers;
      case AcademicScaleType.phosphorus:
        return _phosphorusTiers;
      case AcademicScaleType.potassium:
        return _potassiumTiers;
    }
  }

  int? _getActiveTierIndex() {
    double? val;
    switch (_selectedScale) {
      case AcademicScaleType.ph:
        val = widget.livePh;
        break;
      case AcademicScaleType.nitrogen:
        val = widget.liveNitrogen?.toDouble();
        break;
      case AcademicScaleType.phosphorus:
        val = widget.livePhosphorus?.toDouble();
        break;
      case AcademicScaleType.potassium:
        val = widget.livePotassium?.toDouble();
        break;
    }
    if (val == null) return null;

    final tiers = _currentTiers;
    for (int i = 0; i < tiers.length; i++) {
      if (val >= tiers[i].minVal && val <= tiers[i].maxVal) return i;
    }
    return val < tiers.first.minVal ? 0 : tiers.length - 1;
  }

  String _getLiveValueDisplay() {
    switch (_selectedScale) {
      case AcademicScaleType.ph:
        return widget.livePh != null ? 'pH ${widget.livePh!.toStringAsFixed(2)}' : '--';
      case AcademicScaleType.nitrogen:
        return widget.liveNitrogen != null ? 'N ${widget.liveNitrogen} mg/kg' : '--';
      case AcademicScaleType.phosphorus:
        return widget.livePhosphorus != null ? 'P ${widget.livePhosphorus} mg/kg' : '--';
      case AcademicScaleType.potassium:
        return widget.livePotassium != null ? 'K ${widget.livePotassium} mg/kg' : '--';
    }
  }

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
    final activeTierIndex = _getActiveTierIndex();
    final tiers = _currentTiers;

    return Stack(
      children: [
        // 1. Gesture Layer for Custom Painting & ROI Manipulation
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

        // 2. Floating Detection Toolbar at Left with Academic Color Palette Bar
        Positioned(
          left: 12,
          top: 105,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical Toolbar Body
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xF20B132B), // Deep Cyber Dark
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeColor.withValues(alpha: 0.6), width: 1.2),
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
                    // --- Shape Buttons ---
                    _buildShapeButton(
                      icon: Icons.crop_square_rounded,
                      shape: RoiShape.rectangle,
                      tooltip: 'กรอบสี่เหลี่ยม (Rectangle)',
                      activeColor: activeColor,
                    ),
                    const SizedBox(height: 6),
                    _buildShapeButton(
                      icon: Icons.circle_outlined,
                      shape: RoiShape.circle,
                      tooltip: 'กรอบวงกลม (Circle)',
                      activeColor: activeColor,
                    ),
                    const SizedBox(height: 6),
                    _buildShapeButton(
                      icon: Icons.polyline_rounded,
                      shape: RoiShape.polygon,
                      tooltip: 'โพลีกอนลากเส้นอิสระ (Polygon)',
                      activeColor: activeColor,
                    ),

                    if (widget.currentShape == RoiShape.polygon && _polygonPoints.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.amberAccent, size: 19),
                        tooltip: 'ล้างเส้นวาดใหม่',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _resetPolygon,
                      ),
                    ],

                    // --- Size Buttons ---
                    if (widget.currentShape != RoiShape.polygon) ...[
                      const Divider(color: Colors.white24, height: 12),
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
                      const SizedBox(height: 2),
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
                    ],

                    // --- Academic Color Standard Strip (Table 2.3) ---
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

                    // Swatches Column
                    for (int i = 0; i < tiers.length; i++) ...[
                      _buildColorSwatch(i, tiers[i], activeTierIndex == i),
                      if (i < tiers.length - 1) const SizedBox(height: 3.5),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Expandable Academic Legend Panel
              if (_isLegendOpen) _buildLegendCard(activeTierIndex, tiers),
            ],
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
            color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? activeColor : Colors.white70,
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
        child: Icon(icon, size: 19, color: Colors.cyanAccent),
      ),
    );
  }

  Widget _buildColorSwatch(int index, AcademicTierItem tier, bool isActive) {
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

          // Live Active Pointer Tag
          if (isActive && !_isLegendOpen)
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
                  _getLiveValueDisplay(),
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

  Widget _buildLegendCard(int? activeTierIndex, List<AcademicTierItem> tiers) {
    return Container(
      width: 285,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF80A0F1D), // Dark Cyber Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.4), // RBRU Gold
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(2, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Close Button
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
          const SizedBox(height: 8),

          // Parameter Selector Chips (pH / N / P / K)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildParamChip('pH ดิน', AcademicScaleType.ph),
                const SizedBox(width: 4),
                _buildParamChip('ไนโตรเจน (N)', AcademicScaleType.nitrogen),
                const SizedBox(width: 4),
                _buildParamChip('ฟอสฟอรัส (P)', AcademicScaleType.phosphorus),
                const SizedBox(width: 4),
                _buildParamChip('โพแทสเซียม (K)', AcademicScaleType.potassium),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 12),

          // Live Readout Highlight Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: (activeTierIndex != null ? tiers[activeTierIndex].color : const Color(0xFF00E5FF))
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeTierIndex != null ? tiers[activeTierIndex].color : const Color(0xFF00E5FF),
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
                        : (activeTierIndex != null ? tiers[activeTierIndex].color : Colors.white),
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
                        'กำลังวิเคราะห์สด: ${_getLiveValueDisplay()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (activeTierIndex != null)
                        Text(
                          '${tiers[activeTierIndex].thaiTitle} (${tiers[activeTierIndex].rangeLabel})',
                          style: TextStyle(
                            fontSize: 10,
                            color: tiers[activeTierIndex].color,
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

          // Tiers List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int idx = 0; idx < tiers.length; idx++) ...[
                    Builder(builder: (context) {
                      final tier = tiers[idx];
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
                    if (idx < tiers.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamChip(String label, AcademicScaleType type) {
    final isSelected = _selectedScale == type;
    return InkWell(
      onTap: () => setState(() => _selectedScale = type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.cyanAccent : Colors.white70,
          ),
        ),
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
