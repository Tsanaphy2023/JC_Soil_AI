import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_ph_ht/ui/widgets/interactive_roi_selector.dart';

void main() {
  testWidgets('SoilpH_HT InteractiveRoiSelector renders shape buttons and academic pH strip', (WidgetTester tester) async {
    RoiShape currentShape = RoiShape.rectangle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveRoiSelector(
            currentShape: currentShape,
            onShapeChanged: (shape) => currentShape = shape,
            onRoiUpdated: (roi) {},
            livePh: 6.48,
          ),
        ),
      ),
    );

    // Verify Shape buttons exist
    expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.polyline_rounded), findsOneWidget);

    // Verify Size adjustment buttons
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

    // Verify Academic palette icon button
    expect(find.byIcon(Icons.palette_rounded), findsOneWidget);

    // Verify live indicator badge "pH 6.48" appears on toolbar
    expect(find.text('pH 6.48'), findsOneWidget);

    // Tap palette icon to open Academic Guide Legend Card
    await tester.tap(find.byIcon(Icons.palette_rounded));
    await tester.pumpAndSettle();

    // Verify Academic Legend Card is shown
    expect(find.text('เกณฑ์เฉดสีคู่มือวิชาการ'), findsOneWidget);
    expect(find.text('ตารางที่ 2.3 คู่มือฟิสิกส์เกษตร & กรมพัฒนาที่ดิน'), findsOneWidget);
    expect(find.textContaining('กำลังวิเคราะห์สด: pH 6.48'), findsOneWidget);
    expect(find.text('วิเคราะห์ตรง'), findsOneWidget);
  });
}
