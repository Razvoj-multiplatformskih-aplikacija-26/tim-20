import 'package:mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts', (tester) async {
    await tester.pumpWidget(const MobileApp());
    expect(find.text('Ulaznice'), findsOneWidget);
  });
}
