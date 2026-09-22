import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/ui/views/animated_splash_screen.dart';

void main() {
  group('AnimatedSplashScreen Widget Tests', () {
    testWidgets('renders animated branding, title, and status indicators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedSplashScreen(
            displayDuration: Duration(seconds: 10), // long enough to inspect
          ),
        ),
      );

      // Verify title and subtitle exist
      expect(find.text('JC DIGITAL SOIL AI'), findsOneWidget);
      expect(find.text('EDGE PINN AI'), findsOneWidget);
      expect(find.text('8-in-1 Soil Telemetry & Analyzer'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('RBRU Digital Agriphysics Research Lab'), findsOneWidget);

      // Pump 500ms to test animation progress
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('JC DIGITAL SOIL AI'), findsOneWidget);
    });

    testWidgets('transitions to nextScreen smoothly after display duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedSplashScreen(
            displayDuration: Duration(milliseconds: 300),
            nextScreen: Scaffold(
              body: Center(child: Text('DASHBOARD_TARGET')),
            ),
          ),
        ),
      );

      expect(find.text('JC DIGITAL SOIL AI'), findsOneWidget);

      // Advance clock past display duration and transition duration
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD_TARGET'), findsOneWidget);
      expect(find.text('JC DIGITAL SOIL AI'), findsNothing);
    });
  });
}
