import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_reading.dart';
import 'package:soil_app/domain/models/agronomic_assessment.dart';
import 'package:soil_app/ui/widgets/agronomic_summary_sheet.dart';

void main() {
  group('AgronomicAssessment & AgronomicSummarySheet Tests', () {
    test('AgronomicAssessment evaluates acidic & dry soil with rich advice items', () {
      final reading = SoilReading(
        moisture: 18.0,
        temperature: 29.5,
        conductivity: 150,
        ph: 4.2,
        nitrogen: 12,
        phosphorus: 6,
        potassium: 28,
        fertility: 40,
        timestamp: DateTime.now(),
      );

      final assessment = AgronomicAssessment.evaluate(reading);

      expect(assessment.moistureStatus, equals(MoistureStatus.dry));
      expect(assessment.phStatus, equals(PhStatus.stronglyAcidic));
      expect(assessment.healthScore, lessThan(50.0));
      expect(assessment.healthStatusTitle, contains('ดินวิกฤต'));
      expect(assessment.adviceList.isNotEmpty, isTrue);

      // Should have urgent liming and urgent water action
      final liming = assessment.adviceList.firstWhere((e) => e.category.contains('กรด-ด่าง'));
      expect(liming.priority, equals(AgronomicPriority.urgent));
      expect(liming.actionDose, contains('โดโลไมต์'));

      final water = assessment.adviceList.firstWhere((e) => e.category.contains('น้ำ'));
      expect(water.priority, equals(AgronomicPriority.urgent));
    });

    test('AgronomicAssessment evaluates balanced optimal soil', () {
      final reading = SoilReading(
        moisture: 52.0,
        temperature: 26.0,
        conductivity: 600,
        ph: 6.8,
        nitrogen: 55,
        phosphorus: 28,
        potassium: 95,
        fertility: 120,
        timestamp: DateTime.now(),
      );

      final assessment = AgronomicAssessment.evaluate(reading);

      expect(assessment.moistureStatus, equals(MoistureStatus.optimal));
      expect(assessment.phStatus, equals(PhStatus.optimal));
      expect(assessment.healthScore, greaterThanOrEqualTo(75.0));
      expect(assessment.healthStatusTitle, contains('อุดมสมบูรณ์'));
    });

    testWidgets('AgronomicSummarySheet renders without overflow on phone viewport', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reading = SoilReading(
        moisture: 20.0,
        temperature: 30.0,
        conductivity: 200,
        ph: 4.1,
        nitrogen: 10,
        phosphorus: 5,
        potassium: 25,
        fertility: 30,
        timestamp: DateTime.now(),
      );
      final assessment = AgronomicAssessment.evaluate(reading);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AgronomicSummarySheet.show(context, assessment, reading: reading),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title & elements
      expect(find.text('ผลการวิเคราะห์สภาพดิน & คำแนะนำ'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.textContaining('ข้อเสนอแนะ'), findsWidgets);
      expect(find.textContaining('แถบสีเคมี LDD/FAO'), findsOneWidget);

      // Verify advice items rendered in Tab 1
      expect(find.textContaining('Action Plan'), findsOneWidget);
      expect(find.textContaining('ปริมาณ/วิธีปฏิบัติ:'), findsWidgets);

      // Switch to Tab 2 (Color Scales)
      await tester.tap(find.textContaining('แถบสีเคมี LDD/FAO'));
      await tester.pumpAndSettle();

      // Verify color scale cards rendered without any RenderFlex overflow
      expect(find.textContaining('Soil pH'), findsOneWidget);
      expect(find.textContaining('Available N'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
