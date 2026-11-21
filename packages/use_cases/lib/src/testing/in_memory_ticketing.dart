import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain show remainingSeats;

import '../ports/event_repository.dart';
import '../ports/ticket_repository.dart';

/// Both ports in memory, without latency. Used by package tests and wrapped by the fakes in the apps.
final class InMemoryTicketing implements EventRepository, TicketRepository {
  InMemoryTicketing({List<Event> events = const [], List<Ticket> tickets = const []})
    : _events = {for (final event in events) event.id: event},
      _tickets = {for (final ticket in tickets) ticket.id: ticket};

  final Map<EventId, Event> _events;
  final Map<TicketId, Ticket> _tickets;
  int _nextId = 1;

  @override
  Future<List<Event>> upcoming() async => _events.values.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  @override
  Future<Event?> findEvent(EventId id) async => _events[id];

  @override
  Future<int> remainingSeats(EventId id, {required DateTime now}) async {
    final event = _events[id];
    if (event == null) return 0;
    return domain.remainingSeats(event, await ticketsFor(id), now: now);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async => [
    for (final ticket in _tickets.values)
      if (ticket.holderId == holderId) ticket,
  ];

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async => [
    for (final ticket in _tickets.values)
      if (ticket.eventId == eventId) ticket,
  ];

  @override
  Future<Ticket?> findTicket(TicketId id) async => _tickets[id];

  @override
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  }) async {
    final event = _events[eventId];
    if (event == null) return const Failure(NotFound());
    final result = reserveTickets(
      event: event,
      ticketsOfEvent: await ticketsFor(eventId),
      by: by,
      quantity: quantity,
      now: now,
      newId: () => TicketId('n-${_nextId++}'),
    );
    if (result case Success(:final value)) {
      for (final ticket in value) {
        _tickets[ticket.id] = ticket;
      }
    }
    return result;
  }

  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) async {
    final stored = _tickets[ticket.id];
    if (stored == null) return const Failure(NotFound());
    if (stored.status.runtimeType != from.runtimeType) {
      return Failure(InvalidTransition(from: stored.status, to: ticket.status));
    }
    _tickets[ticket.id] = ticket;
    return Success(ticket);
  }
}
