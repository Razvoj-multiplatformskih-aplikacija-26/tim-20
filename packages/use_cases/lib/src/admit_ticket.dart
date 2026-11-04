import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain;

import 'clock.dart';
import 'ports/ticket_repository.dart';

final class AdmitTicket {
  const AdmitTicket({required this.tickets, required this.clock});

  final TicketRepository tickets;
  final Clock clock;

  Future<Result<Ticket>> call({required TicketId id, required User by}) async {
    final ticket = await tickets.findTicket(id);
    if (ticket == null) return const Failure(NotFound());
    return switch (domain.admitTicket(ticket, by: by, now: clock.now())) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success((await tickets.saveAll([value])).single),
    };
  }
}
