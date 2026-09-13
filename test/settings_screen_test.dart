import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:soil_app/ui/views/settings_screen.dart';
import 'package:soil_app/ui/viewmodels/soil_sensor_viewmodel.dart';
import 'package:soil_app/core/localization/language_provider.dart';

void main() {
  testWidgets('SettingsScreen displays User Manual PDF Download section and actions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<SoilSensorViewModel>(create: (_) => SoilSensorViewModel()),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sensor & Hardware Config'), findsOneWidget);

    final titleFinder = find.text('คู่มือการใช้งานและเอกสารวิชาการ (User Manual & Academic Handbook)');
    await tester.scrollUntilVisible(titleFinder, 300);
    await tester.pumpAndSettle();

    expect(titleFinder, findsOneWidget);
    expect(find.text('JC Digital Soil AI Beginner Guide'), findsOneWidget);
    expect(find.text('ดาวน์โหลดคู่มือ PDF'), findsOneWidget);
    expect(find.text('เปิดอ่าน / ส่งต่อ'), findsOneWidget);
  });
}
