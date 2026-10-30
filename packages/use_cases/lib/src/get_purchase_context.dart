import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';
import 'read_models.dart';

final class GetPurchaseContext {
  const GetPurchaseContext({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Null for an unknown event.
  Future<PurchaseContext?> call({required EventId eventId, required UserId holder}) async {
    final event = await events.findEvent(eventId);
    if (event == null) return null;

    final now = clock.now();
    final ticketsOfEvent = await tickets.ticketsFor(eventId);
    return PurchaseContext(
      event: event,
      remaining: remainingSeats(event, ticketsOfEvent, now: now),
      alreadyHeld: heldBy(holder, eventId, ticketsOfEvent, now: now),
    );
  }
}
