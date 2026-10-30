import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  final clock = FixedClock(now);
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
  const marko = User(id: UserId('u-marko'), name: 'Marko Marković', role: Role.visitor);

  Event event(String id, {required Duration startsIn, int capacity = 10}) => Event(
    id: EventId(id),
    name: 'Događaj $id',
    venue: 'RAF',
    startsAt: now.add(startsIn),
    priceRsd: 500,
    capacity: capacity,
    organizerId: const UserId('u-org'),
  );

  var counter = 0;
  Ticket ticket({required TicketStatus status, String event = 'e-1', User holder = ana}) {
    final id = TicketId('t-${++counter}');
    return Ticket(
      id: id,
      eventId: EventId(event),
      holderId: holder.id,
      holderName: holder.name,
      status: status,
      createdAt: now.subtract(const Duration(hours: 1)),
      code: 'T20-${id.value}',
    );
  }

  final nextWeek = event('e-1', startsIn: const Duration(days: 7));
  final tomorrow = event('e-2', startsIn: const Duration(hours: 20));
  final yesterday = event('e-3', startsIn: const Duration(days: -1));

  setUp(() => counter = 0);

  group('GetUpcomingEvents', () {
    test('returns only events that start after now, with the seats left', () async {
      final store = InMemoryTicketing(
        events: [nextWeek, tomorrow, yesterday],
        tickets: [
          ticket(status: Paid(paidAt: now)),
          ticket(
            status: Reserved(expiresAt: now.add(reservationHold)),
            holder: marko,
          ),
          ticket(
            status: Cancelled(at: now, by: ana.id),
          ),
          ticket(
            status: Paid(paidAt: now),
            event: 'e-3',
          ),
        ],
      );
      final listings = await GetUpcomingEvents(events: store, tickets: store, clock: clock)();
      expect(listings, [EventListing(event: tomorrow, remaining: 10), EventListing(event: nextWeek, remaining: 8)]);
    });
  });

  group('GetMyTickets', () {
    test("returns the visitor's tickets with their event and actions, sorted by start", () async {
      final paidNextWeek = ticket(status: Paid(paidAt: now));
      final usedYesterday = ticket(
        status: Used(scannedAt: now, scannedBy: const UserId('u-usher')),
        event: 'e-3',
      );
      final paidTomorrow = ticket(
        status: Paid(paidAt: now),
        event: 'e-2',
      );
      final store = InMemoryTicketing(
        events: [nextWeek, tomorrow, yesterday],
        tickets: [
          paidNextWeek,
          usedYesterday,
          paidTomorrow,
          ticket(
            status: Paid(paidAt: now),
            holder: marko,
          ),
        ],
      );
      final owned = await GetMyTickets(events: store, tickets: store, clock: clock)(ana);
      expect(owned, [
        OwnedTicket(ticket: usedYesterday, event: yesterday, actions: const {}),
        OwnedTicket(ticket: paidTomorrow, event: tomorrow, actions: const {}),
        OwnedTicket(ticket: paidNextWeek, event: nextWeek, actions: const {VisitorAction.cancel}),
      ]);
    });

    test('shows a reservation past its deadline as expired', () async {
      final deadline = now.subtract(const Duration(minutes: 1));
      final stale = ticket(status: Reserved(expiresAt: deadline));
      final store = InMemoryTicketing(events: [nextWeek], tickets: [stale]);
      final owned = await GetMyTickets(events: store, tickets: store, clock: clock)(ana);
      expect(owned.single.ticket.status, Expired(at: deadline));
      expect(owned.single.actions, isEmpty);
    });
  });

  group('GetPurchaseContext', () {
    test('counts the seats left and the active tickets already held', () async {
      final store = InMemoryTicketing(
        events: [nextWeek],
        tickets: [
          ticket(status: Paid(paidAt: now)),
          ticket(status: Reserved(expiresAt: now.subtract(const Duration(minutes: 1)))),
          ticket(
            status: Paid(paidAt: now),
            holder: marko,
          ),
        ],
      );
      final context = await GetPurchaseContext(events: store, tickets: store, clock: clock)(
        eventId: nextWeek.id,
        holder: ana.id,
      );
      expect(context, PurchaseContext(event: nextWeek, remaining: 8, alreadyHeld: 1));
    });

    test('is null for an unknown event', () async {
      final store = InMemoryTicketing();
      final context = await GetPurchaseContext(events: store, tickets: store, clock: clock)(
        eventId: const EventId('nope'),
        holder: ana.id,
      );
      expect(context, isNull);
    });
  });

  group('ReserveTickets', () {
    var ids = 0;
    TicketId newId() => TicketId('n-${++ids}');

    test('saves the new tickets', () async {
      final store = InMemoryTicketing(events: [nextWeek]);
      final reserve = ReserveTickets(events: store, tickets: store, clock: clock, newId: newId);
      final result = await reserve(eventId: nextWeek.id, by: ana, quantity: 2);
      expect(result, isA<Success<List<Ticket>>>());
      expect(await store.ticketsOf(ana.id), result.valueOrNull);
      expect((await store.ticketsOf(ana.id)).length, 2);
    });

    test('returns NotFound for an unknown event', () async {
      final store = InMemoryTicketing();
      final reserve = ReserveTickets(events: store, tickets: store, clock: clock, newId: newId);
      final result = await reserve(eventId: const EventId('nope'), by: ana, quantity: 1);
      expect(result, const Failure<List<Ticket>>(NotFound()));
    });
  });

  group('PayTicket', () {
    test('saves the paid ticket', () async {
      final reservedTicket = ticket(status: Reserved(expiresAt: now.add(reservationHold)));
      final store = InMemoryTicketing(events: [nextWeek], tickets: [reservedTicket]);
      final result = await PayTicket(tickets: store, clock: clock)(id: reservedTicket.id, by: ana);
      expect(result.valueOrNull?.status, Paid(paidAt: now));
      expect((await store.findTicket(reservedTicket.id))?.status, Paid(paidAt: now));
    });

    test('returns NotFound for an unknown ticket', () async {
      final store = InMemoryTicketing();
      final result = await PayTicket(tickets: store, clock: clock)(id: const TicketId('nope'), by: ana);
      expect(result, const Failure<Ticket>(NotFound()));
    });
  });

  group('CancelTicket', () {
    test('saves the cancelled ticket', () async {
      final paidTicket = ticket(status: Paid(paidAt: now));
      final store = InMemoryTicketing(events: [nextWeek], tickets: [paidTicket]);
      final result = await CancelTicket(events: store, tickets: store, clock: clock)(id: paidTicket.id, by: ana);
      expect(result.valueOrNull?.status, Cancelled(at: now, by: ana.id));
      expect((await store.findTicket(paidTicket.id))?.status, Cancelled(at: now, by: ana.id));
    });

    test('rejects a late cancellation and saves nothing', () async {
      final paidTicket = ticket(
        status: Paid(paidAt: now),
        event: 'e-2',
      );
      final store = InMemoryTicketing(events: [tomorrow], tickets: [paidTicket]);
      final result = await CancelTicket(events: store, tickets: store, clock: clock)(id: paidTicket.id, by: ana);
      expect(result, const Failure<Ticket>(CancellationTooLate()));
      expect(await store.findTicket(paidTicket.id), paidTicket);
    });
  });
}
