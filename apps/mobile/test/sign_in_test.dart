import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/purchase_screen.dart';
import 'package:mobile/widgets/ticket_tile.dart';

import 'support.dart';

void main() {
  const organizer = User(id: UserId('u-org'), name: 'Jovana Organizator', role: Role.organizer);

  Future<void> signIn(WidgetTester tester, String username) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'lozinka');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
  }

  testWidgets('events are visible without signing in', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(signedIn: false)));
    await settle(tester);

    expect(find.text('Brucošijada 2026'), findsOneWidget);
    expect(find.text('Prijavi se'), findsNothing);
  });

  testWidgets('Kupi without a session opens the sign-in screen and returns to the purchase after signing in', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(signedIn: false)));
    await settle(tester);

    await tester.tap(find.text('Hakaton: 24 sata koda'));
    await settle(tester);
    await tester.tap(find.text('Kupi karte'));
    await settle(tester);
    expect(appBarTitle('Prijava'), findsOneWidget);

    await signIn(tester, 'ana');
    expect(find.byType(PurchaseScreen), findsOneWidget);
    expect(appBarTitle('Kupovina'), findsOneWidget);
  });

  testWidgets('my tickets without a session asks to sign in', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(signedIn: false)));
    await settle(tester);

    await openTab(tester, 'Moje karte');
    expect(find.text('Prijavite se da vidite svoje karte.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
    await signIn(tester, 'ana');
    expect(appBarTitle('Moje karte'), findsOneWidget);
    expect(find.byType(TicketTile), findsWidgets);
  });

  testWidgets("a staff account is refused with 'Aplikacija je za posetioce. Osoblje koristi backoffice.'", (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(signedIn: false, user: organizer)));
    await settle(tester);

    await openTab(tester, 'Moje karte');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
    await signIn(tester, 'organizator');

    expect(appBarTitle('Prijava'), findsOneWidget);
    expect(find.text('Aplikacija je za posetioce. Osoblje koristi backoffice.'), findsOneWidget);
  });

  testWidgets('logging out after confirming returns my tickets to the sign-in prompt', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    await openTab(tester, 'Moje karte');
    expect(find.byType(TicketTile), findsWidgets);

    await tester.tap(find.byTooltip('Odjavi se'));
    await settle(tester);
    await tester.tap(find.text('Odustani'));
    await settle(tester);
    expect(find.byType(TicketTile), findsWidgets);

    await tester.tap(find.byTooltip('Odjavi se'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Odjavi se'));
    await settle(tester);
    expect(find.text('Prijavite se da vidite svoje karte.'), findsOneWidget);
    expect(find.byTooltip('Odjavi se'), findsNothing);
  });
}
