import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

const organizer = User(id: UserId('u-org'), name: 'Organizator', role: Role.organizer);
const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

final now = DateTime.utc(2026, 11, 1, 18);
final clock = FixedClock(now);

/// A clock a test can move forward while the bloc is running.
final class MovableClock implements Clock {
  MovableClock(this.instant);

  DateTime instant;

  @override
  DateTime now() => instant;
}

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

/// Both ports over [InMemoryTicketing], failing the next [failingRequests] calls like the fakes in the apps.
final class FlakyTicketing implements EventRepository, TicketRepository {
  FlakyTicketing({List<Event> events = const [], List<Ticket> tickets = const []})
    : _store = InMemoryTicketing(events: events, tickets: tickets);

  final InMemoryTicketing _store;
  int failingRequests = 0;
  int saves = 0;

  void _maybeFail() {
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('simulated outage');
    }
  }

  @override
  Future<List<Event>> upcoming() async {
    _maybeFail();
    return _store.upcoming();
  }

  @override
  Future<Event?> findEvent(EventId id) async {
    _maybeFail();
    return _store.findEvent(id);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async {
    _maybeFail();
    return _store.ticketsOf(holderId);
  }

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async {
    _maybeFail();
    return _store.ticketsFor(eventId);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) async {
    _maybeFail();
    return _store.findTicket(id);
  }

  @override
  Future<List<Ticket>> saveAll(List<Ticket> tickets) async {
    _maybeFail();
    saves++;
    return _store.saveAll(tickets);
  }
}
