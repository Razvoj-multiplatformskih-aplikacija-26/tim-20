import 'package:backoffice/widgets/ticket_detail_panel.dart';
import 'package:backoffice/widgets/ticket_list.dart';
import 'package:backoffice/widgets/ticket_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  Finder inPanel(String text) => find.descendant(of: find.byType(TicketDetailPanel), matching: find.text(text));

  testWidgets('a wide window shows the table and a narrow one shows the list', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    expect(find.byType(TicketTable), findsOneWidget);
    expect(find.byType(TicketList), findsNothing);

    useWindow(tester, width: 700, height: 800);
    await settle(tester);
    expect(find.byType(TicketList), findsOneWidget);
    expect(find.byType(TicketTable), findsNothing);
  });

  testWidgets('the selection survives narrowing the window', (tester) async {
    final semantics = tester.ensureSemantics();
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(inPanel('T20-t-13'), findsOneWidget);

    useWindow(tester, width: 700, height: 800);
    await settle(tester);

    expect(currentLocation(tester), '/dogadjaji/e-a?selected=t-13');
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Jelena Jovanović, T20-t-13, Plaćena'))),
      isSemantics(isSelected: true),
    );
    expect(find.text('T20-t-13'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a narrow window opens the detail in a bottom sheet', (tester) async {
    useWindow(tester, width: 700, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);

    await tester.tap(find.text('T20-t-01'));
    await settle(tester);

    expect(inPanel('T20-t-01'), findsOneWidget);
    expect(inPanel('Potvrdi plaćanje'), findsOneWidget);
  });

  testWidgets('the address opens the ticket it names', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a?selected=t-05');
    await settle(tester);

    expect(inPanel('T20-t-05'), findsOneWidget);
  });

  testWidgets('a change of address while the tickets load wins over the first request', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    final slow = fakeDependencies(latency: const Duration(milliseconds: 50));
    await pumpBackoffice(tester, location: '/dogadjaji/e-a?selected=t-05', dependencies: slow);
    await tester.pump();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/dogadjaji/e-a?selected=t-07');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await settle(tester);

    expect(inPanel('T20-t-07'), findsOneWidget);
    expect(inPanel('T20-t-05'), findsNothing);
    expect(currentLocation(tester), '/dogadjaji/e-a?selected=t-07');
  });

  testWidgets('an unknown ticket in the address shows the table without a panel', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a?selected=nema');
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TicketTable), findsOneWidget);
    expect(find.byType(TicketDetailPanel), findsNothing);
    expect(currentLocation(tester), '/dogadjaji/e-a');
  });
}
