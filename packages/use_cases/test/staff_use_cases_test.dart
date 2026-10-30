import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 18);
  final clock = FixedClock(now);

  const organizer = User(id: UserId('u-org'), name: 'Organizator', role: Role.organizer);
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

  Event event(String id, {Duration startsIn = const Duration(days: 7), UserId organizerId = const UserId('u-org')}) =>
      Event(
        id: EventId(id),
        name: 'Događaj $id',
        venue: 'RAF',
        startsAt: now.add(startsIn),
        priceRsd: 500,
        capacity: 10,
        organizerId: organizerId,
      );

  Ticket ticket(String id, {TicketStatus? status, String event = 'e-1'}) => Ticket(
    id: TicketId(id),
    eventId: EventId(event),
    holderId: ana.id,
    holderName: ana.name,
    status: status ?? Reserved(expiresAt: now.add(reservationHold)),
    createdAt: now.subtract(const Duration(hours: 1)),
    code: 'T20-$id',
  );

  group('GetEventTickets', () {
    test('returns the tickets of the event with their status at now, the summary and the allowed actions', () async {
      final concert = event('e-1');
      final deadline = now.subtract(const Duration(minutes: 1));
      final reserved = ticket('t-1');
      final ranOut = ticket('t-2', status: Reserved(expiresAt: deadline));
      final store = InMemoryTicketing(
        events: [concert],
        tickets: [
          reserved,
          ranOut,
          ticket('t-3', event: 'e-2'),
        ],
      );

      final result = await GetEventTickets(events: store, tickets: store, clock: clock)(
        eventId: concert.id,
        staff: organizer,
      );

      final shown = [reserved, ranOut.copyWith(status: Expired(at: deadline))];
      expect(result?.event, concert);
      expect(result?.tickets, shown);
      expect(result?.summary, summarize(concert, shown, now: now));
      expect(result?.actions, {
        reserved.id: staffActionsFor(reserved, concert, by: organizer, now: now),
        ranOut.id: const <StaffAction>{},
      });
    });

    test('returns null for an unknown event', () async {
      final store = InMemoryTicketing();
      final getEventTickets = GetEventTickets(events: store, tickets: store, clock: clock);
      expect(await getEventTickets(eventId: const EventId('missing'), staff: organizer), isNull);
    });
  });

  group('ConfirmPayment', () {
    test('saves the paid ticket', () async {
      final store = InMemoryTicketing(events: [event('e-1')], tickets: [ticket('t-1')]);
      final confirm = ConfirmPayment(tickets: store, clock: clock);

      final result = await confirm(id: const TicketId('t-1'), by: organizer);

      expect(result.valueOrNull?.status, Paid(paidAt: now, confirmedBy: organizer.id));
      expect((await store.findTicket(const TicketId('t-1')))?.status, Paid(paidAt: now, confirmedBy: organizer.id));
    });

    test('returns NotFound for an unknown id', () async {
      final store = InMemoryTicketing();
      final confirm = ConfirmPayment(tickets: store, clock: clock);
      expect(await confirm(id: const TicketId('missing'), by: organizer), const Failure<Ticket>(NotFound()));
    });
  });

  test('AdmitTicket lets a ticket in once and rejects the second attempt', () async {
    final store = InMemoryTicketing(
      events: [event('e-1')],
      tickets: [ticket('t-1', status: Paid(paidAt: now))],
    );
    final admit = AdmitTicket(tickets: store, clock: clock);

    final first = await admit(id: const TicketId('t-1'), by: organizer);
    final second = await admit(id: const TicketId('t-1'), by: organizer);

    expect(first.valueOrNull?.status, Used(scannedAt: now, scannedBy: organizer.id));
    expect(second, const Failure<Ticket>(TicketAlreadyUsed()));
  });

  group('VoidTicket', () {
    test('cancels a paid ticket even one hour before the start', () async {
      final soon = event('e-1', startsIn: const Duration(hours: 1));
      final store = InMemoryTicketing(
        events: [soon],
        tickets: [ticket('t-1', status: Paid(paidAt: now))],
      );
      final voidTicket = VoidTicket(events: store, tickets: store, clock: clock);

      final result = await voidTicket(id: const TicketId('t-1'), by: organizer, reason: 'Duplikat.');

      expect(result.valueOrNull?.status, Cancelled(at: now, by: organizer.id, reason: 'Duplikat.'));
      expect((await store.findTicket(const TicketId('t-1')))?.status, isA<Cancelled>());
    }, skip: 'Waits for cancelTicket from the visitor rules (D1).');

    test('returns NotFound for an unknown id', () async {
      final store = InMemoryTicketing();
      final voidTicket = VoidTicket(events: store, tickets: store, clock: clock);
      expect(
        await voidTicket(id: const TicketId('missing'), by: organizer, reason: ''),
        const Failure<Ticket>(NotFound()),
      );
    });
  });

  test('GetOrganizerEvents returns only the events of the organizer, sorted by start', () async {
    final store = InMemoryTicketing(
      events: [
        event('e-late', startsIn: const Duration(days: 9)),
        event('e-other', organizerId: const UserId('u-other')),
        event('e-early', startsIn: const Duration(days: 2)),
      ],
    );

    final events = await GetOrganizerEvents(events: store)(organizer);

    expect(events.map((e) => e.id), [const EventId('e-early'), const EventId('e-late')]);
  });
}
