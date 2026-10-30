import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/ticket_repository.dart';

final class PayTicket {
  const PayTicket({required this.tickets, required this.clock});

  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by}) async {
    final ticket = await tickets.findTicket(id);
    if (ticket == null) return const Failure(NotFound());

    return switch (payTicket(ticket, by: by, now: clock.now())) {
      Success(:final value) => Success((await tickets.saveAll([value])).single),
      Failure(:final error) => Failure(error),
    };
  }
}
