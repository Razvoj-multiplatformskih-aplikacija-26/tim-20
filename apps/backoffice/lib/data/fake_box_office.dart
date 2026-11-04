import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

/// Both ports over the seed in memory, with latency and two counters the debug menu sets.
final class FakeBoxOffice implements EventRepository, TicketRepository {
  FakeBoxOffice({required Clock clock, this.latency = const Duration(milliseconds: 700)})
    : _store = InMemoryTicketing(events: seedEvents(clock.now()), tickets: seedTickets(clock.now()));

  final Duration latency;
  final InMemoryTicketing _store;
  int failingRequests = 0;
  int emptyResponses = 0;

  Future<void> _roundTrip() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  bool get _empty {
    if (emptyResponses == 0) return false;
    emptyResponses--;
    return true;
  }

  @override
  Future<List<Event>> upcoming() async {
    await _roundTrip();
    return _empty ? [] : _store.upcoming();
  }

  @override
  Future<Event?> findEvent(EventId id) async {
    await _roundTrip();
    return _store.findEvent(id);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async {
    await _roundTrip();
    return _empty ? [] : _store.ticketsOf(holderId);
  }

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async {
    await _roundTrip();
    return _empty ? [] : _store.ticketsFor(eventId);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) async {
    await _roundTrip();
    return _store.findTicket(id);
  }

  @override
  Future<List<Ticket>> saveAll(List<Ticket> tickets) async {
    await _roundTrip();
    return _store.saveAll(tickets);
  }
}
