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
    // D2
    throw UnimplementedError();
  }
}
