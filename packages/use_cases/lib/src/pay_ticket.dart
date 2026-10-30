import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/ticket_repository.dart';

final class PayTicket {
  const PayTicket({required this.tickets, required this.clock});

  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by}) async {
    // D2
    throw UnimplementedError();
  }
}
