import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';
import 'read_models.dart';

final class GetEventTickets {
  const GetEventTickets({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Null for an unknown event.
  Future<EventTickets?> call({required EventId eventId, required User staff}) async {
    final event = await events.findEvent(eventId);
    if (event == null) return null;
    final now = clock.now();
    final shown = [
      for (final ticket in await tickets.ticketsFor(eventId))
        ticket.copyWith(status: effectiveStatus(ticket, now: now)),
    ];
    return EventTickets(
      event: event,
      tickets: shown,
      summary: summarize(event, shown, now: now),
      actions: {for (final ticket in shown) ticket.id: staffActionsFor(ticket, event, by: staff, now: now)},
    );
  }
}
