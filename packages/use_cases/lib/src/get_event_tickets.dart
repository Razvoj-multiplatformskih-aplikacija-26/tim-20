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
    // F2
    throw UnimplementedError();
  }
}
