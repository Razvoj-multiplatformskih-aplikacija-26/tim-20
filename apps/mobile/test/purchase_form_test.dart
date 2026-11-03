import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  Future<void> openForm(WidgetTester tester, String eventId) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: '/dogadjaj/$eventId/kupovina'));
    await settle(tester);
  }

  testWidgets('purchase form rejects 5 tickets with a Serbian message', (tester) async {
    await openForm(tester, 'e-5');

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.tap(find.text('Kupi'));
    await settle(tester);

    expect(find.text('Broj karata je od 1 do 4.'), findsOneWidget);
    expect(appBarTitle('Kupovina'), findsOneWidget);
  });

  testWidgets('purchase form respects tickets already held', (tester) async {
    await openForm(tester, 'e-1');

    await tester.enterText(find.byType(TextFormField), '2');
    await tester.tap(find.text('Kupi'));
    await settle(tester);

    expect(find.textContaining('već imate 3'), findsOneWidget);
  });

  testWidgets('valid purchase navigates to Moje karte', (tester) async {
    await openForm(tester, 'e-5');

    await tester.enterText(find.byType(TextFormField), '2');
    await tester.tap(find.text('Kupi'));
    await settle(tester);

    expect(appBarTitle('Moje karte'), findsOneWidget);
    expect(find.text('Rezervisano je 2 karte. Platite u roku od 15 minuta.'), findsOneWidget);
  });
}
