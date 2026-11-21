import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);

  Event event(String id, {required int inDays}) => Event(
    id: EventId(id),
    name: 'Događaj $id',
    venue: 'RAF',
    startsAt: now.add(Duration(days: inDays)),
    priceRsd: 500,
    capacity: 10,
    organizerId: const UserId('u-org'),
  );

  Ticket ticket(String id, {String event = 'e-1', String holder = 'u-ana'}) => Ticket(
    id: TicketId(id),
    eventId: EventId(event),
    holderId: UserId(holder),
    holderName: holder,
    status: Reserved(expiresAt: now.add(reservationHold)),
    createdAt: now,
    code: 'T20-$id',
  );

  test('upcoming returns every event sorted by start', () async {
    final store = InMemoryTicketing(events: [event('e-late', inDays: 5), event('e-early', inDays: 1)]);
    final events = await store.upcoming();
    expect(events.map((e) => e.id), [const EventId('e-early'), const EventId('e-late')]);
  });

  const ana = User(id: UserId('u-ana'), name: 'u-ana', role: Role.visitor);

  test('reserve stores new reservations with fresh ids', () async {
    final store = InMemoryTicketing(events: [event('e-1', inDays: 3)]);

    final result = await store.reserve(eventId: const EventId('e-1'), by: ana, quantity: 2, now: now);

    final created = result.valueOrNull!;
    expect(created.map((t) => t.id), [const TicketId('n-1'), const TicketId('n-2')]);
    expect(created.map((t) => t.status), everyElement(Reserved(expiresAt: now.add(reservationHold))));
    expect(await store.ticketsOf(ana.id), created);
  });

  test('reserve rejects more than the remaining seats and stores nothing', () async {
    final store = InMemoryTicketing(
      events: [event('e-1', inDays: 3)],
      tickets: [for (var i = 1; i <= 9; i++) ticket('t-$i', holder: 'u-$i')],
    );

    final result = await store.reserve(eventId: const EventId('e-1'), by: ana, quantity: 2, now: now);

    expect(result, const Failure<List<Ticket>>(NotEnoughSeats(1)));
    expect(await store.ticketsOf(ana.id), isEmpty);
  });

  test('reserve of an unknown event is NotFound', () async {
    final store = InMemoryTicketing();
    final result = await store.reserve(eventId: const EventId('nope'), by: ana, quantity: 1, now: now);
    expect(result, const Failure<List<Ticket>>(NotFound()));
  });

  test('save replaces a ticket whose stored status is still the one it was read in', () async {
    final store = InMemoryTicketing(tickets: [ticket('t-1')]);
    final paid = ticket('t-1').copyWith(status: Paid(paidAt: now));

    final result = await store.save(paid, from: ticket('t-1').status);

    expect(result, Success(paid));
    expect(await store.findTicket(const TicketId('t-1')), paid);
  });

  test('save refuses when another call changed the status meanwhile', () async {
    final paid = ticket('t-1').copyWith(status: Paid(paidAt: now));
    final store = InMemoryTicketing(tickets: [paid]);
    final cancelled = ticket('t-1').copyWith(
      status: Cancelled(at: now, by: ana.id),
    );

    final result = await store.save(cancelled, from: ticket('t-1').status);

    expect(result, Failure<Ticket>(InvalidTransition(from: paid.status, to: cancelled.status)));
    expect(await store.findTicket(const TicketId('t-1')), paid);
  });

  test('remainingSeats counts the active tickets of the event', () async {
    final store = InMemoryTicketing(
      events: [event('e-1', inDays: 3)],
      tickets: [
        ticket('t-1'),
        ticket('t-2'),
        ticket('t-3', event: 'e-2'),
      ],
    );
    expect(await store.remainingSeats(const EventId('e-1'), now: now), 8);
    expect(await store.remainingSeats(const EventId('nope'), now: now), 0);
  });
}
