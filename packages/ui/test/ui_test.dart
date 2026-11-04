import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  final t = DateTime.utc(2026, 11, 4, 12);
  const u = UserId('u-org');
  final statuses = <TicketStatus>[
    Reserved(expiresAt: t),
    Paid(paidAt: t),
    Used(scannedAt: t, scannedBy: u),
    Cancelled(at: t, by: u),
    Expired(at: t),
  ];

  test('every domain error has a Serbian message', () {
    final errors = <DomainError>[
      const InvalidTicketQuantity(0),
      const TicketLimitExceeded(alreadyHeld: 3, requested: 2),
      const NotEnoughSeats(0),
      const EventAlreadyStarted(),
      const CancellationTooLate(),
      const ReservationExpired(),
      const TicketAlreadyUsed(),
      InvalidTransition(from: statuses[1], to: statuses[1]),
      const NotAllowed(),
      const NotFound(),
    ];
    for (final error in errors) {
      expect(error.message, isNotEmpty, reason: '$error');
    }
    expect(const TicketLimitExceeded(alreadyHeld: 3, requested: 2).message, contains('3'));
  });

  group('TicketsTheme', () {
    test('uses Inter from this package', () {
      expect(TicketsTheme.light().textTheme.bodyMedium?.fontFamily, 'packages/ui/Inter');
      expect(TicketsTheme.dark().textTheme.bodyMedium?.fontFamily, 'packages/ui/Inter');
    });

    test('gives every status its own color in both schemes', () {
      for (final theme in [TicketsTheme.light(), TicketsTheme.dark()]) {
        final colors = theme.statusColors;
        final backgrounds = {for (final status in statuses) colors.of(status).$1};
        expect(backgrounds, hasLength(statuses.length), reason: '${theme.brightness}');
      }
    });
  });

  group('StatusBadge', () {
    testWidgets('shows the label and is announced as a status', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: TicketsTheme.light(), home: StatusBadge(statuses[1])));
      expect(find.text('Plaćena'), findsOneWidget);
      expect(find.bySemanticsLabel('Stanje: Plaćena'), findsOneWidget);
    });
  });

  group('FailureView', () {
    testWidgets('calls onRetry on Pokušaj ponovo', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: TicketsTheme.light(),
          home: FailureView(onRetry: () => retried++),
        ),
      );
      await tester.tap(find.text('Pokušaj ponovo'));
      expect(retried, 1);
    });
  });
}
