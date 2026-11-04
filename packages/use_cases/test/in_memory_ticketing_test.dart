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

  test('saveAll adds new tickets and replaces changed ones by id', () async {
    final store = InMemoryTicketing(tickets: [ticket('t-1')]);
    final paid = ticket('t-1').copyWith(status: Paid(paidAt: now));
    await store.saveAll([paid, ticket('t-2', event: 'e-2', holder: 'u-marko')]);

    expect(await store.findTicket(const TicketId('t-1')), paid);
    expect(await store.ticketsOf(const UserId('u-ana')), [paid]);
    expect(await store.ticketsFor(const EventId('e-2')), [ticket('t-2', event: 'e-2', holder: 'u-marko')]);
    expect(await store.findEvent(const EventId('e-1')), isNull);
  });
}
