import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';
import 'read_models.dart';

final class GetMyTickets {
  const GetMyTickets({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Tickets of [visitor] sorted by the start of their event, past events included.
  Future<List<OwnedTicket>> call(User visitor) async {
    final now = clock.now();
    final owned = <OwnedTicket>[];
    for (final ticket in await tickets.ticketsOf(visitor.id)) {
      final event = await events.findEvent(ticket.eventId);
      if (event == null) continue;
      owned.add(
        OwnedTicket(
          ticket: ticket.copyWith(status: effectiveStatus(ticket, now: now)),
          event: event,
          actions: visitorActionsFor(ticket, event, by: visitor, now: now),
        ),
      );
    }
    return owned..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));
  }
}
