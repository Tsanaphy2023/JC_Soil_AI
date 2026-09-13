import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/main.dart';

void main() {
  testWidgets('SoilParameterApp renders dashboard correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SoilParameterApp());
    expect(find.text('SOIL AI ANALYZER'), findsOneWidget);
    expect(find.text('Save to *.xls'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
  });
}
