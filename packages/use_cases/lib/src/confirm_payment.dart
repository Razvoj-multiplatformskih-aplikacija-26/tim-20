import 'package:domain/domain.dart';

import 'change_ticket.dart';
import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

final class ConfirmPayment {
  const ConfirmPayment({required this.events, required this.tickets, required this.clock});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by}) => changeTicket(
    tickets,
    events,
    id,
    by: by,
    change: (ticket) => confirmPayment(ticket, by: by, now: clock.now()),
  );
}
