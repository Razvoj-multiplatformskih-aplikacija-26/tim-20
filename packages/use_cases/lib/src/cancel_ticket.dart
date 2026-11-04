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
    final ticket = await tickets.findTicket(id);
    if (ticket == null) return const Failure(NotFound());
    final event = await events.findEvent(ticket.eventId);
    if (event == null) return const Failure(NotFound());

    return switch (cancelTicket(ticket, event, by: by, now: clock.now(), reason: reason)) {
      Success(:final value) => Success((await tickets.saveAll([value])).single),
      Failure(:final error) => Failure(error),
    };
  }
}
