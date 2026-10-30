import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class ReserveTickets {
  const ReserveTickets({required this.events, required this.tickets, required this.clock, required this.newId});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;
  final TicketId Function() newId;

  Future<Result<List<Ticket>>> call({required EventId eventId, required User by, required int quantity}) async {
    // D2
    throw UnimplementedError();
  }
}
