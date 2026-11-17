import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 18);
  final clock = FixedClock(now);

  const organizer = User(id: UserId('u-org'), name: 'Organizator', role: Role.organizer);
  const usher = User(id: UserId('u-usher'), name: 'Redar', role: Role.usher);
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

    test('a visitor may see their own ticket but not confirm its payment', () async {
      final store = InMemoryTicketing(events: [event('e-1')], tickets: [ticket('t-1')]);
      final confirm = ConfirmPayment(tickets: store, clock: clock);
      expect(await confirm(id: const TicketId('t-1'), by: ana), const Failure<Ticket>(NotAllowed()));
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

  test('AdmitTicket that loses the race to another admission reads again and reports TicketAlreadyUsed', () async {
    final store = RacingTicketing(
      InMemoryTicketing(
        events: [event('e-1')],
        tickets: [ticket('t-1', status: Paid(paidAt: now))],
      ),
      meanwhile: (ticket) => ticket.copyWith(
        status: Used(scannedAt: now, scannedBy: usher.id),
      ),
    );

    final result = await AdmitTicket(tickets: store, clock: clock)(id: const TicketId('t-1'), by: organizer);

    expect(result, const Failure<Ticket>(TicketAlreadyUsed()));
    expect((await store.findTicket(const TicketId('t-1')))?.status, Used(scannedAt: now, scannedBy: usher.id));
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
    });

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

  test('GetOrganizerEvents shows an usher every event', () async {
    final store = InMemoryTicketing(
      events: [
        event('e-1'),
        event('e-other', organizerId: const UserId('u-other')),
      ],
    );
    final events = await GetOrganizerEvents(events: store)(usher);
    expect(events.map((e) => e.id), containsAll([const EventId('e-1'), const EventId('e-other')]));
  });
}

/// Lets another call change the ticket between the read and the first save, as a second client would.
final class RacingTicketing implements TicketRepository {
  RacingTicketing(this._store, {required this.meanwhile});

  final InMemoryTicketing _store;
  final Ticket Function(Ticket stored) meanwhile;
  var _raced = false;

  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) async {
    if (!_raced) {
      _raced = true;
      final stored = (await _store.findTicket(ticket.id))!;
      await _store.save(meanwhile(stored), from: stored.status);
    }
    return _store.save(ticket, from: from);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) => _store.findTicket(id);

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) => _store.ticketsFor(eventId);

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) => _store.ticketsOf(holderId);

  @override
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  }) => _store.reserve(eventId: eventId, by: by, quantity: quantity, now: now);
}
