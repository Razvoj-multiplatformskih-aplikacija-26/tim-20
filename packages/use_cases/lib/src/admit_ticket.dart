import 'package:domain/domain.dart';

import 'change_ticket.dart';
import 'clock.dart';
import 'ports/ticket_repository.dart';

final class AdmitTicket {
  const AdmitTicket({required this.tickets, required this.clock});

  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by}) => changeTicket(
    tickets,
    id,
    by: by,
    change: (ticket) => admitTicket(ticket, by: by, now: clock.now()),
  );
}
