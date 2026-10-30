import 'package:backoffice/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts', (tester) async {
    await tester.pumpWidget(const BackofficeApp());
    expect(find.text('Ulaznice · organizator'), findsOneWidget);
  });
}
