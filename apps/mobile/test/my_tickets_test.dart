import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'support.dart';

Finder badge(String label) => find.descendant(of: find.byType(StatusBadge), matching: find.text(label));

void main() {
  testWidgets('my tickets shows four states', (tester) async {
    usePhoneSize(tester);
    final dependencies = fakeDependencies(latency: const Duration(seconds: 1));
    await tester.pumpWidget(appWith(dependencies));
    await tester.pump(const Duration(seconds: 2));

    dependencies.fake!.failingRequests = 1;
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Moje karte')));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Podaci trenutno nisu dostupni.'), findsOneWidget);

    dependencies.fake!.emptyResponses = 1;
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Nemate karata.'), findsOneWidget);

    await tester.fling(find.byType(EmptyView), const Offset(0, 400), 1000);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byType(StatusBadge), findsWidgets);
  });

  testWidgets('filter chips change the list', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    await openTab(tester, 'Moje karte');
    expect(badge('Plaćena'), findsWidgets);

    await tester.tap(find.text('Rezervisane'));
    await settle(tester);
    expect(badge('Plaćena'), findsNothing);
    expect(badge('Rezervisana'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Otkazane'));
    await tester.tap(find.text('Otkazane'));
    await settle(tester);
    expect(badge('Rezervisana'), findsNothing);
    expect(badge('Otkazana'), findsOneWidget);
  });

  testWidgets('seeded list contains every status label', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    await openTab(tester, 'Moje karte');

    const filters = [
      ('Rezervisane', 'Rezervisana'),
      ('Plaćene', 'Plaćena'),
      ('Iskorišćene', 'Iskorišćena'),
      ('Otkazane', 'Otkazana'),
      ('Istekle', 'Istekla'),
    ];
    for (final (chip, label) in filters) {
      await tester.ensureVisible(find.text(chip));
      await tester.tap(find.text(chip));
      await settle(tester);
      expect(badge(label), findsWidgets, reason: label);
    }
  });

  testWidgets('pay turns Rezervisana into Plaćena', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: '/karte/a-2'));
    await settle(tester);
    expect(badge('Rezervisana'), findsOneWidget);

    await tester.tap(find.text('Plati'));
    await settle(tester);
    expect(find.text('Karta je plaćena.'), findsOneWidget);
    expect(badge('Plaćena'), findsOneWidget);
  });

  testWidgets('cancel asks for confirmation', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: '/karte/a-1'));
    await settle(tester);

    await tester.tap(find.text('Otkaži'));
    await settle(tester);
    expect(find.text('Otkazati kartu?'), findsOneWidget);
    expect(find.text('Ovo ne može da se vrati.'), findsOneWidget);

    await tester.tap(find.text('Odustani'));
    await settle(tester);
    expect(badge('Plaćena'), findsOneWidget);
    expect(find.text('Karta je otkazana.'), findsNothing);

    await tester.tap(find.text('Otkaži'));
    await settle(tester);
    await tester.tap(find.text('Otkaži kartu'));
    await settle(tester);
    expect(find.text('Karta je otkazana.'), findsOneWidget);
    expect(badge('Otkazana'), findsOneWidget);
  });

  testWidgets('cancel button is hidden for a ticket less than 24h before start and the detail explains why', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: '/karte/a-5'));
    await settle(tester);

    expect(badge('Plaćena'), findsOneWidget);
    expect(find.text('Otkaži'), findsNothing);
    expect(find.text(const CancellationTooLate().message), findsOneWidget);
  });
}
