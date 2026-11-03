import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/ticket_detail_screen.dart';

import 'support.dart';

void main() {
  testWidgets('two tabs switch between Događaji and Moje karte', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    expect(appBarTitle('Događaji'), findsOneWidget);

    await openTab(tester, 'Moje karte');
    expect(appBarTitle('Moje karte'), findsOneWidget);
    expect(appBarTitle('Događaji'), findsNothing);

    await openTab(tester, 'Događaji');
    expect(appBarTitle('Događaji'), findsOneWidget);
  });

  testWidgets('deep link /karte/<id> opens the ticket detail', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: '/karte/a-1'));
    await settle(tester);

    expect(find.byType(TicketDetailScreen), findsOneWidget);
    expect(appBarTitle('Karta'), findsOneWidget);
  });
}
