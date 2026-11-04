import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';
import 'read_models.dart';

final class GetUpcomingEvents {
  const GetUpcomingEvents({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Only events that start after now, with the seats that are still free.
  Future<List<EventListing>> call() async {
    final now = clock.now();
    final upcoming = (await events.upcoming()).where((event) => event.startsAt.isAfter(now));
    return [
      for (final event in upcoming)
        EventListing(
          event: event,
          remaining: remainingSeats(event, await tickets.ticketsFor(event.id), now: now),
        ),
    ];
  }
}
