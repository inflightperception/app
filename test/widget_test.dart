import 'package:flutter_test/flutter_test.dart';
import 'package:perceptionv1/main.dart';

void main() {
  testWidgets('app starts on login screen', (tester) async {
    await tester.pumpWidget(const OfpAnalyzerApp());

    expect(find.text('Overflow'), findsOneWidget);
    expect(find.text('Fuel Intelligence Platform'), findsOneWidget);
    expect(find.text('New user? Create an account now'), findsOneWidget);
    expect(
      find.textContaining('Overflow helps pilots and operations teams'),
      findsOneWidget,
    );
    expect(find.text('12,400+'), findsNothing);
  });
}
