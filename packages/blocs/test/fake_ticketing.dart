import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

/// Shared examples for the bloc tests.
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

Ticket ticket(String id, {required TicketStatus status, String event = 'e-1', User holder = ana}) => Ticket(
  id: TicketId(id),
  eventId: EventId(event),
  holderId: holder.id,
  holderName: holder.name,
  status: status,
  createdAt: now.subtract(const Duration(hours: 1)),
  code: 'T20-$id',
);

/// In-memory ports that fail the next [failingRequests] calls with a [RepositoryException].
final class FakeTicketing implements EventRepository, TicketRepository {
  FakeTicketing({List<Event> events = const [], List<Ticket> tickets = const []})
    : _store = InMemoryTicketing(events: events, tickets: tickets);

  final InMemoryTicketing _store;
  int failingRequests = 0;

  void _roundTrip() {
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  @override
  Future<List<Event>> upcoming() async {
    _roundTrip();
    return _store.upcoming();
  }

  @override
  Future<Event?> findEvent(EventId id) async {
    _roundTrip();
    return _store.findEvent(id);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async {
    _roundTrip();
    return _store.ticketsOf(holderId);
  }

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async {
    _roundTrip();
    return _store.ticketsFor(eventId);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) async {
    _roundTrip();
    return _store.findTicket(id);
  }

  @override
  Future<List<Ticket>> saveAll(List<Ticket> tickets) async {
    _roundTrip();
    return _store.saveAll(tickets);
  }
}
