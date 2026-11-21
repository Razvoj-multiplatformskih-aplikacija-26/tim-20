import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';
import 'package:mobile/widgets/ticket_tile.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

void main() {
  Finder badge(String label) => find.descendant(of: find.byType(StatusBadge), matching: find.text(label));

  testWidgets("the server down shows 'Nema veze sa serverom.' with 'Pokušaj ponovo' on events and my tickets", (
    tester,
  ) async {
    usePhoneSize(tester);
    final dependencies = fakeDependencies();
    dependencies.fake!.failingRequests = 1;
    await tester.pumpWidget(appWith(dependencies));
    await settle(tester);
    expect(find.text('Nema veze sa serverom.'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.text('Brucošijada 2026'), findsOneWidget);

    await openTab(tester, 'Moje karte');
    dependencies.fake!.failingRequests = 1;
    await pullToRefresh(tester, find.byType(TicketTile).first);
    await settle(tester);
    expect(find.text('Nema veze sa serverom.'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.byType(TicketTile), findsWidgets);
  });

  testWidgets("an expiration shows the sign-in screen with 'Prijava je istekla. Prijavite se ponovo.'", (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    await openTab(tester, 'Moje karte');

    tester.element(find.byType(NavigationBar)).read<SessionBloc>().add(const SessionExpired());
    await settle(tester);
    expect(appBarTitle('Prijava'), findsOneWidget);
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'ana');
    await tester.enterText(find.byType(TextField).at(1), 'lozinka');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
    expect(appBarTitle('Moje karte'), findsOneWidget);
    expect(find.byType(TicketTile), findsWidgets);
  });

  group("an unknown error code shows 'Server nije prihvatio zahtev.' without technical text", () {
    testWidgets('when paying in my tickets', (tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies();
      await tester.pumpWidget(appWith(dependencies, initialLocation: '/karte/a-2'));
      await settle(tester);

      dependencies.fake!
        ..failingWith = RepositoryFailure.refused
        ..failingRequests = 1;
      await tester.tap(find.text('Plati'));
      await settle(tester);
      expect(find.text('Server nije prihvatio zahtev.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(badge('Rezervisana'), findsOneWidget);
    });

    testWidgets('when buying', (tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies();
      await tester.pumpWidget(appWith(dependencies, initialLocation: '/dogadjaj/e-1/kupovina'));
      await settle(tester);

      dependencies.fake!
        ..failingWith = RepositoryFailure.refused
        ..failingRequests = 1;
      await tester.tap(find.text('Kupi'));
      await settle(tester);
      expect(find.text('Server nije prihvatio zahtev.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });
  });

  testWidgets('a rejected payment shows the reason and the reloaded tickets', (tester) async {
    usePhoneSize(tester);
    final clock = MovingClock(wednesdayNoon);
    await tester.pumpWidget(appWith(fakeDependencies(clock: clock), initialLocation: '/karte/a-2'));
    await settle(tester);
    expect(badge('Rezervisana'), findsOneWidget);

    clock.instant = wednesdayNoon.add(const Duration(minutes: 6));
    await tester.tap(find.text('Plati'));
    await settle(tester);

    expect(find.text(const ReservationExpired().message), findsOneWidget);
    expect(badge('Istekla'), findsOneWidget);
    expect(find.text('Plati'), findsNothing);
  });

  testWidgets('pull to refresh reloads the events and my tickets', (tester) async {
    usePhoneSize(tester);
    final dependencies = fakeDependencies();
    await tester.pumpWidget(appWith(dependencies));
    await settle(tester);
    expect(find.text('Još 1 mesto'), findsOneWidget);

    await tester.runAsync(
      () =>
          dependencies.fake!.reserve(eventId: const EventId('e-3'), by: otherVisitor, quantity: 1, now: wednesdayNoon),
    );
    await pullToRefresh(tester, find.text('Brucošijada 2026'));
    await settle(tester);
    expect(find.text('Još 1 mesto'), findsNothing);
    expect(find.text('Rasprodato'), findsOneWidget);

    await openTab(tester, 'Moje karte');
    await tester.tap(find.text('Rezervisane'));
    await settle(tester);
    expect(badge('Rezervisana'), findsNWidgets(2));

    await tester.runAsync(
      () => dependencies.fake!.reserve(eventId: const EventId('e-1'), by: ana, quantity: 1, now: wednesdayNoon),
    );
    await pullToRefresh(tester, find.byType(TicketTile).first);
    await settle(tester);
    await tester.tap(find.text('Rezervisane'));
    await settle(tester);
    expect(badge('Rezervisana'), findsNWidgets(3));
  });
}
