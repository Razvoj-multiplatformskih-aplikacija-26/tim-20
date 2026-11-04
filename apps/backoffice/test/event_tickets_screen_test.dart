import 'package:backoffice/widgets/summary_header.dart';
import 'package:backoffice/widgets/ticket_detail_panel.dart';
import 'package:backoffice/widgets/ticket_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  Finder inPanel(String text) => find.descendant(of: find.byType(TicketDetailPanel), matching: find.text(text));
  Finder inTable(String text) => find.descendant(of: find.byType(TicketTable), matching: find.text(text));

  testWidgets('the header sums up sales, occupancy and admissions', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);

    expect(find.text('Brucošijada'), findsOneWidget);
    final header = find.byType(SummaryHeader);
    expect(find.descendant(of: header, matching: find.text('34 / 50')), findsOneWidget);
    expect(find.descendant(of: header, matching: find.text('68%')), findsOneWidget);
    expect(find.descendant(of: header, matching: find.text('8')), findsOneWidget);
  });

  testWidgets('the ticket screen shows loading, failure with retry, empty, not found and the table', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    final deps = fakeDependencies()..fake!.failingRequests = 1;
    await pumpBackoffice(tester, dependencies: deps, location: '/dogadjaji/e-a');
    expect(find.byType(LoadingView), findsOneWidget);

    await settle(tester);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.byType(TicketTable), findsOneWidget);

    await pumpBackoffice(tester, location: '/dogadjaji/e-b');
    await settle(tester);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Stand-up veče'), findsOneWidget);

    await pumpBackoffice(tester, location: '/dogadjaji/nema');
    await settle(tester);
    expect(find.text('Događaj nije pronađen.'), findsOneWidget);
  });

  testWidgets('tapping a row opens the detail panel with the code and the allowed actions', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    expect(find.byType(TicketDetailPanel), findsNothing);

    await tester.tap(inTable('T20-t-01'));
    await settle(tester);

    expect(inPanel('T20-t-01'), findsOneWidget);
    expect(inPanel('Potvrdi plaćanje'), findsOneWidget);
    expect(inPanel('Poništi'), findsOneWidget);
    expect(inPanel('Pusti na ulaz'), findsNothing);
    expect(currentLocation(tester), '/dogadjaji/e-a?selected=t-01');
  });

  testWidgets('confirming a payment from the panel turns the badge into Plaćena and says so', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    await tester.tap(inTable('T20-t-01'));
    await settle(tester);
    expect(inPanel('Rezervisana'), findsOneWidget);

    await tester.tap(inPanel('Potvrdi plaćanje'));
    await settle(tester);

    expect(find.text('Plaćanje je potvrđeno.'), findsOneWidget);
    expect(inPanel('Plaćena'), findsOneWidget);
    expect(inPanel('Pusti na ulaz'), findsOneWidget);
  });

  testWidgets('voiding asks for a reason first and Odustani changes nothing', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    await tester.tap(inTable('T20-t-01'));
    await settle(tester);

    await tester.tap(inPanel('Poništi'));
    await settle(tester);
    expect(find.text('Poništiti kartu?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('Odustani'));
    await settle(tester);
    expect(find.text('Poništiti kartu?'), findsNothing);
    expect(inPanel('Rezervisana'), findsOneWidget);
  });

  group('voiding', () {
    testWidgets('with a reason cancels the ticket', (tester) async {
      useWindow(tester, width: 1200, height: 800);
      await pumpBackoffice(tester, location: '/dogadjaji/e-a');
      await settle(tester);
      await tester.tap(inTable('T20-t-01'));
      await settle(tester);

      await tester.tap(inPanel('Poništi'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Duplikat.');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Poništi')));
      await settle(tester);

      expect(find.text('Karta je poništena.'), findsOneWidget);
      expect(inPanel('Otkazana'), findsOneWidget);
    });
  });

  testWidgets('the Plaćena chip keeps only paid tickets in the table', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    expect(inTable('Rezervisana'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Plaćena'));
    await settle(tester);

    expect(inTable('Rezervisana'), findsNothing);
    expect(inTable('Plaćena'), findsWidgets);
  });
}
