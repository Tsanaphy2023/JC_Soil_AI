import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/main.dart';

void main() {
  testWidgets('SoilParameterApp renders dashboard correctly with default Thai language and flag selector', (WidgetTester tester) async {
    await tester.pumpWidget(const SoilParameterApp());
    expect(find.text('JC'), findsOneWidget);
    expect(find.text('SOIL'), findsOneWidget);
    expect(find.text('AI ANALYZER'), findsOneWidget);
    expect(find.text('บันทึกข้อมูล *.xls'), findsOneWidget);
    expect(find.text('ประวัติการวัด'), findsOneWidget);
    expect(find.text('🇹🇭'), findsOneWidget);
    expect(find.text('TH'), findsOneWidget);
  });
}
