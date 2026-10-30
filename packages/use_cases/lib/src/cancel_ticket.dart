import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class CancelTicket {
  const CancelTicket({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by, String reason = ''}) async {
    // D2
    throw UnimplementedError();
  }
}
