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

  /// Null for an unknown event. The visitor's own tickets give the limit; the seats come from the event repository.
  Future<PurchaseContext?> call({required EventId eventId, required UserId holder}) async {
    final event = await events.findEvent(eventId);
    if (event == null) return null;

    final now = clock.now();
    return PurchaseContext(
      event: event,
      remaining: await events.remainingSeats(eventId, now: now),
      alreadyHeld: heldBy(holder, eventId, await tickets.ticketsOf(holder), now: now),
    );
  }
}
