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
    final event = await events.findEvent(eventId);
    if (event == null) return const Failure(NotFound());

    final result = reserveTickets(
      event: event,
      ticketsOfEvent: await tickets.ticketsFor(eventId),
      by: by,
      quantity: quantity,
      now: clock.now(),
      newId: newId,
    );
    return switch (result) {
      Success(:final value) => Success(await tickets.saveAll(value)),
      Failure(:final error) => Failure(error),
    };
  }
}
