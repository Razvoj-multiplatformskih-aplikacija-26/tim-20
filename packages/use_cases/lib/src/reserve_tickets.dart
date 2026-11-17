import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class ReserveTickets {
  const ReserveTickets({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// The store runs reserveTickets, because the free seats depend on the tickets of every visitor.
  Future<Result<List<Ticket>>> call({required EventId eventId, required User by, required int quantity}) async {
    final event = await events.findEvent(eventId);
    if (event == null) return const Failure(NotFound());
    return tickets.reserve(eventId: eventId, by: by, quantity: quantity, now: clock.now());
  }
}
