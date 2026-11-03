import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

/// Both ports over the in-memory store, with latency and a way to simulate an outage or an empty answer.
final class FakeTicketing implements EventRepository, TicketRepository {
  FakeTicketing({required this.clock, this.latency = const Duration(milliseconds: 700)})
    : _store = InMemoryTicketing(events: seedEvents(clock.now()), tickets: seedTickets(clock.now()));

  final Clock clock;
  final Duration latency;
  final InMemoryTicketing _store;
  int failingRequests = 0;
  int emptyResponses = 0;
  int _nextId = 1;

  TicketId newId() => TicketId('t-${_nextId++}');

  /// Lists and writes pay the latency; lookups by id are answered from the same round trip.
  Future<void> _roundTrip({bool slow = true}) async {
    if (slow) await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  bool _answersEmpty() {
    if (emptyResponses == 0) return false;
    emptyResponses--;
    return true;
  }

  @override
  Future<List<Event>> upcoming() async {
    await _roundTrip();
    if (_answersEmpty()) return const [];
    return _store.upcoming();
  }

  @override
  Future<Event?> findEvent(EventId id) async {
    await _roundTrip(slow: false);
    return _store.findEvent(id);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async {
    await _roundTrip();
    if (_answersEmpty()) return const [];
    return _store.ticketsOf(holderId);
  }

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async {
    await _roundTrip(slow: false);
    return _store.ticketsFor(eventId);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) async {
    await _roundTrip(slow: false);
    return _store.findTicket(id);
  }

  @override
  Future<List<Ticket>> saveAll(List<Ticket> tickets) async {
    await _roundTrip();
    return _store.saveAll(tickets);
  }
}
