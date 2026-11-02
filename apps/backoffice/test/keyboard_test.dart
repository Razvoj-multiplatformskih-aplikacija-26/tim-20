import 'package:backoffice/widgets/ticket_detail_panel.dart';
import 'package:backoffice/widgets/ticket_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  Finder inPanel(String text) => find.descendant(of: find.byType(TicketDetailPanel), matching: find.text(text));

  Future<void> pumpTickets(WidgetTester tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
  }

  testWidgets('the table takes focus at once and the arrow keys move the outlined row', (tester) async {
    await pumpTickets(tester);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ticket table');
    expect(tester.widget<TicketTable>(find.byType(TicketTable)).cursor, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    expect(tester.widget<TicketTable>(find.byType(TicketTable)).cursor, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await settle(tester);
    expect(tester.widget<TicketTable>(find.byType(TicketTable)).cursor, 0);
  });

  testWidgets('the outline disappears when the table loses focus', (tester) async {
    await pumpTickets(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    expect(tester.widget<TicketTable>(find.byType(TicketTable)).cursor, isNull);
  });

  testWidgets('Enter opens the ticket under the cursor and Esc closes it', (tester) async {
    await pumpTickets(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(inPanel('T20-t-02'), findsOneWidget);
    expect(currentLocation(tester), '/dogadjaji/e-a?selected=t-02');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byType(TicketDetailPanel), findsNothing);
    expect(currentLocation(tester), '/dogadjaji/e-a');
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ticket table');
  });

  testWidgets('C confirms the payment of the selected reserved ticket', (tester) async {
    await pumpTickets(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(inPanel('Rezervisana'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await settle(tester);

    expect(find.text('Plaćanje je potvrđeno.'), findsOneWidget);
    expect(inPanel('Plaćena'), findsOneWidget);
  });

  testWidgets('U does nothing on a reserved ticket', (tester) async {
    await pumpTickets(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
    await settle(tester);

    expect(find.byType(SnackBar), findsNothing);
    expect(inPanel('Rezervisana'), findsOneWidget);
  });

  testWidgets('X opens the void dialog for the selected ticket', (tester) async {
    await pumpTickets(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await settle(tester);

    expect(find.text('Poništiti kartu?'), findsOneWidget);
  });

  testWidgets('? opens the overview of shortcuts', (tester) async {
    await pumpTickets(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await settle(tester);

    expect(find.text('Prečice'), findsOneWidget);
    expect(find.text('Potvrdi plaćanje izabrane karte'), findsOneWidget);
  });
}
