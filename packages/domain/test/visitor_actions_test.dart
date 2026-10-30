import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('reserveTickets', () {
    var counter = 0;
    TicketId newId() => TicketId('n-${++counter}');

    setUp(() => counter = 0);

    test('creates N reserved tickets that expire after the hold', () {
      final result = reserveTickets(
        event: event(),
        ticketsOfEvent: const [],
        by: ana,
        quantity: 3,
        now: now,
        newId: newId,
      );

      final tickets = result.valueOrNull!;
      expect(tickets, hasLength(3));
      expect(tickets.map((t) => t.id.value), ['n-1', 'n-2', 'n-3']);
      for (final t in tickets) {
        expect(t.status, Reserved(expiresAt: now.add(reservationHold)));
        expect(t.eventId, const EventId('e-1'));
        expect(t.holderId, ana.id);
        expect(t.holderName, ana.name);
        expect(t.createdAt, now);
        expect(t.code, 'T20-${t.id.value}');
      }
    });

    test('rejects staff', () {
      final result = reserveTickets(
        event: event(),
        ticketsOfEvent: const [],
        by: organizer,
        quantity: 1,
        now: now,
        newId: newId,
      );
      expect(result, const Failure<List<Ticket>>(NotAllowed()));
    });

    test('rejects an event that already started', () {
      final result = reserveTickets(
        event: event(startsAt: now),
        ticketsOfEvent: const [],
        by: ana,
        quantity: 1,
        now: now,
        newId: newId,
      );
      expect(result, const Failure<List<Ticket>>(EventAlreadyStarted()));
    });

    test('counts only active tickets toward the limit of 4', () {
      final held = [
        ticket(status: paid()),
        ticket(status: paid()),
        ticket(status: used()),
        ticket(status: cancelled()),
        ticket(status: reserved(left: const Duration(minutes: -1))),
      ];
      Result<List<Ticket>> reserve(int quantity) =>
          reserveTickets(event: event(), ticketsOfEvent: held, by: ana, quantity: quantity, now: now, newId: newId);

      expect(reserve(1), isA<Success<List<Ticket>>>());
      expect(reserve(2), const Failure<List<Ticket>>(TicketLimitExceeded(alreadyHeld: 3, requested: 2)));
    });

    test('rejects more tickets than there are seats left', () {
      final taken = [for (var i = 0; i < 4; i++) ticket(status: paid(), holder: marko)];
      final result = reserveTickets(
        event: event(capacity: 5),
        ticketsOfEvent: taken,
        by: ana,
        quantity: 2,
        now: now,
        newId: newId,
      );
      expect(result, const Failure<List<Ticket>>(NotEnoughSeats(1)));
    });
  });

  group('payTicket', () {
    test('marks a reserved ticket paid by its holder', () {
      final result = payTicket(
        ticket(status: reserved()),
        by: ana,
        now: now,
      );
      expect(result.valueOrNull?.status, Paid(paidAt: now));
    });

    test("rejects another visitor's ticket", () {
      expect(
        payTicket(
          ticket(status: reserved()),
          by: marko,
          now: now,
        ),
        const Failure<Ticket>(NotAllowed()),
      );
    });

    test('rejects an expired reservation', () {
      final result = payTicket(
        ticket(status: reserved(left: const Duration(minutes: -1))),
        by: ana,
        now: now,
      );
      expect(result, const Failure<Ticket>(ReservationExpired()));
    });

    test('rejects a ticket that is already paid', () {
      final result = payTicket(
        ticket(status: paid()),
        by: ana,
        now: now,
      );
      expect(
        result,
        Failure<Ticket>(
          InvalidTransition(
            from: paid(),
            to: Paid(paidAt: now),
          ),
        ),
      );
    });
  });

  group('cancelTicket', () {
    test('lets the visitor cancel exactly 24 hours before the start', () {
      final e = event(startsAt: now.add(cancellationNotice));
      final result = cancelTicket(
        ticket(status: paid()),
        e,
        by: ana,
        now: now,
      );
      expect(result.valueOrNull?.status, Cancelled(at: now, by: ana.id));
    });

    test('rejects the visitor one second past the notice', () {
      final e = event(startsAt: now.add(cancellationNotice - const Duration(seconds: 1)));
      final result = cancelTicket(
        ticket(status: paid()),
        e,
        by: ana,
        now: now,
      );
      expect(result, const Failure<Ticket>(CancellationTooLate()));
    });

    test('lets the organizer cancel one hour before the start, with a reason', () {
      final e = event(startsAt: now.add(const Duration(hours: 1)));
      final result = cancelTicket(
        ticket(status: paid()),
        e,
        by: organizer,
        now: now,
        reason: 'Otkazan nastup',
      );
      expect(result.valueOrNull?.status, Cancelled(at: now, by: organizer.id, reason: 'Otkazan nastup'));
    });

    test('rejects everyone after the start', () {
      final e = event(startsAt: now);
      expect(
        cancelTicket(
          ticket(status: paid()),
          e,
          by: ana,
          now: now,
        ),
        const Failure<Ticket>(EventAlreadyStarted()),
      );
      expect(
        cancelTicket(
          ticket(status: paid()),
          e,
          by: organizer,
          now: now,
        ),
        const Failure<Ticket>(EventAlreadyStarted()),
      );
    });

    test('rejects a used ticket', () {
      final result = cancelTicket(
        ticket(status: used()),
        event(),
        by: organizer,
        now: now,
      );
      expect(
        result,
        Failure<Ticket>(
          InvalidTransition(
            from: used(),
            to: Cancelled(at: now, by: organizer.id),
          ),
        ),
      );
    });

    test("rejects another visitor's ticket", () {
      expect(
        cancelTicket(
          ticket(status: paid()),
          event(),
          by: marko,
          now: now,
        ),
        const Failure<Ticket>(NotAllowed()),
      );
    });
  });

  group('visitorActionsFor', () {
    test('a reservation long before the start can be paid or cancelled', () {
      expect(
        visitorActionsFor(
          ticket(status: reserved()),
          event(),
          by: ana,
          now: now,
        ),
        {VisitorAction.pay, VisitorAction.cancel},
      );
    });

    test('a paid ticket 10 hours before the start has no actions', () {
      final e = event(startsAt: now.add(const Duration(hours: 10)));
      expect(
        visitorActionsFor(
          ticket(status: paid()),
          e,
          by: ana,
          now: now,
        ),
        isEmpty,
      );
    });

    test('a paid ticket 3 days before the start can be cancelled', () {
      final e = event(startsAt: now.add(const Duration(days: 3)));
      expect(
        visitorActionsFor(
          ticket(status: paid()),
          e,
          by: ana,
          now: now,
        ),
        {VisitorAction.cancel},
      );
    });

    test('an expired ticket has no actions', () {
      expect(
        visitorActionsFor(
          ticket(status: expired()),
          event(),
          by: ana,
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
