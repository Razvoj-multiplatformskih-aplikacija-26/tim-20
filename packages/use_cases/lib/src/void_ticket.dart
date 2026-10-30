import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class VoidTicket {
  const VoidTicket({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Cancels the ticket through cancelTicket, so the organizer has no 24 hour notice.
  Future<Result<Ticket>> call({required TicketId id, required User by, required String reason}) async {
    // F2
    throw UnimplementedError();
  }
}
