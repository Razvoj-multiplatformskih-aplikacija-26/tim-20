import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('soldCount', () {
    test('counts reserved, paid and used tickets', () {
      final tickets = [ticket(status: reserved()), ticket(status: paid()), ticket(status: used())];
      expect(soldCount(tickets, now: now), 3);
    });

    test('does not count cancelled, expired or a reservation past its deadline', () {
      final tickets = [
        ticket(status: cancelled()),
        ticket(status: expired()),
        ticket(status: reserved(left: const Duration(minutes: -1))),
        ticket(status: paid()),
      ];
      expect(soldCount(tickets, now: now), 1);
    });
  });

  group('remainingSeats', () {
    test('is zero when every seat is taken', () {
      final tickets = [for (var i = 0; i < 5; i++) ticket(status: paid())];
      expect(remainingSeats(event(capacity: 5), tickets, now: now), 0);
    });

    test('is never negative', () {
      final tickets = [for (var i = 0; i < 7; i++) ticket(status: paid())];
      expect(remainingSeats(event(capacity: 5), tickets, now: now), 0);
    });

    test('subtracts only active tickets from the capacity', () {
      final tickets = [ticket(status: paid()), ticket(status: cancelled())];
      expect(remainingSeats(event(capacity: 5), tickets, now: now), 4);
    });
  });

  group('heldBy', () {
    test('counts only active tickets of that holder for that event', () {
      const other = EventId('e-2');
      final tickets = [
        ticket(status: paid()),
        ticket(status: reserved()),
        ticket(status: cancelled()),
        ticket(status: reserved(left: const Duration(minutes: -5))),
        ticket(status: paid(), holder: marko),
        ticket(status: paid(), eventId: other),
      ];
      expect(heldBy(ana.id, const EventId('e-1'), tickets, now: now), 2);
      expect(heldBy(marko.id, const EventId('e-1'), tickets, now: now), 1);
      expect(heldBy(ana.id, other, tickets, now: now), 1);
    });
  });
}
