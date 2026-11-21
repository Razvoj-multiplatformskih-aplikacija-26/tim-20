import 'package:domain/domain.dart';

import 'change_ticket.dart';
import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class CancelTicket {
  const CancelTicket({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by, String reason = ''}) async {
    final event = await _eventOf(id);
    if (event == null) return const Failure(NotFound());
    return changeTicket(
      tickets,
      events,
      id,
      by: by,
      change: (ticket) => cancelTicket(ticket, event, by: by, now: clock.now(), reason: reason),
    );
  }

  Future<Event?> _eventOf(TicketId id) async {
    final ticket = await tickets.findTicket(id);
    return ticket == null ? null : events.findEvent(ticket.eventId);
  }
}
