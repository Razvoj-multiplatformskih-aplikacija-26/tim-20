import 'package:domain/domain.dart';

import '../ports/event_repository.dart';
import '../ports/ticket_repository.dart';

/// Both ports in memory, without latency. Used by package tests and wrapped by the fakes in the apps.
final class InMemoryTicketing implements EventRepository, TicketRepository {
  InMemoryTicketing({List<Event> events = const [], List<Ticket> tickets = const []})
    : _events = {for (final event in events) event.id: event},
      _tickets = {for (final ticket in tickets) ticket.id: ticket};

  final Map<EventId, Event> _events;
  final Map<TicketId, Ticket> _tickets;

  @override
  Future<List<Event>> upcoming() async => _events.values.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  @override
  Future<Event?> findEvent(EventId id) async => _events[id];

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
  Future<List<Ticket>> saveAll(List<Ticket> tickets) async {
    for (final ticket in tickets) {
      _tickets[ticket.id] = ticket;
    }
    return List.of(tickets);
  }
}
