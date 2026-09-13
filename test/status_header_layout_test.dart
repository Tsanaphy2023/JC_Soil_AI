import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:soil_app/core/localization/language_provider.dart';
import 'package:soil_app/data/models/geo_location_data.dart';
import 'package:soil_app/data/services/usb_sensor_service.dart';
import 'package:soil_app/ui/widgets/status_header.dart';

void main() {
  group('StatusHeader Layout Tests', () {
    testWidgets('renders user wireframe layout: tall LOGO on left and 3 rows on right', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyLocation = GeoLocationData(
        latitude: 12.62353,
        longitude: 102.17448,
        altitude: -20.3,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: StatusHeader(
                status: UsbConnectionStatus.disconnected,
                isAiCalibrated: true,
                location: dummyLocation,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Left Tall LOGO card contents
      expect(find.text('JC'), findsOneWidget);
      expect(find.text('AI'), findsWidgets);
      expect(find.text('SOIL'), findsOneWidget);
      expect(find.text('AI ANALYZER'), findsOneWidget);

      // Verify Row 1: Camera, Gallery, Language Flag/Code, Circular Settings
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.text('🇹🇭'), findsOneWidget);
      expect(find.text('TH'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Verify Row 2: Connection Status & AI Calibration
      expect(find.text('ไม่ได้เชื่อมต่อ'), findsOneWidget);
      expect(find.text('การสอบเทียบ AI: เปิด'), findsOneWidget);

      // Verify Row 3: GPS Geotag
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.textContaining('12.62353° N, 102.17448° E'), findsOneWidget);

      // Ensure no layout overflow exception was thrown
      expect(tester.takeException(), isNull);
    });
  });
}
