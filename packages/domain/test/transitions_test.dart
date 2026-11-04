import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final t = DateTime.utc(2026, 11, 4, 12);
  const u = UserId('u-org');

  group('canTransition', () {
    test('allows exactly five transitions out of twenty-five', () {
      final statuses = <TicketStatus>[
        Reserved(expiresAt: t),
        Paid(paidAt: t),
        Used(scannedAt: t, scannedBy: u),
        Cancelled(at: t, by: u),
        Expired(at: t),
      ];
      final allowed = <(Type, Type)>[];
      for (final from in statuses) {
        for (final to in statuses) {
          if (canTransition(from, to)) allowed.add((from.runtimeType, to.runtimeType));
        }
      }
      expect(allowed, [(Reserved, Paid), (Reserved, Cancelled), (Reserved, Expired), (Paid, Used), (Paid, Cancelled)]);
    });

    test('a used ticket cannot be cancelled and an expired one cannot be paid', () {
      expect(canTransition(Used(scannedAt: t, scannedBy: u), Cancelled(at: t, by: u)), isFalse);
      expect(canTransition(Expired(at: t), Paid(paidAt: t)), isFalse);
    });
  });

  group('effectiveStatus', () {
    final ticket = Ticket(
      id: const TicketId('t-1'),
      eventId: const EventId('e-1'),
      holderId: const UserId('u-ana'),
      holderName: 'Ana Anić',
      status: Reserved(expiresAt: t),
      createdAt: t.subtract(reservationHold),
      code: 'T20-t-1',
    );

    test('a reservation is reserved until its deadline', () {
      expect(effectiveStatus(ticket, now: t.subtract(const Duration(minutes: 1))), Reserved(expiresAt: t));
      expect(effectiveStatus(ticket, now: t), Reserved(expiresAt: t));
    });

    test('a reservation past its deadline is expired at the deadline', () {
      expect(effectiveStatus(ticket, now: t.add(const Duration(minutes: 1))), Expired(at: t));
      expect(ticket.isActiveAt(t.add(const Duration(minutes: 1))), isFalse);
    });

    test('other statuses do not depend on time', () {
      final paid = ticket.copyWith(status: Paid(paidAt: t));
      expect(effectiveStatus(paid, now: t.add(const Duration(days: 1))), Paid(paidAt: t));
    });
  });
}
