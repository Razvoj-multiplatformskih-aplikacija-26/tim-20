import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';
import 'package:mobile/widgets/ticket_tile.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  Finder badge(String label) => find.descendant(of: find.byType(StatusBadge), matching: find.text(label));

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
