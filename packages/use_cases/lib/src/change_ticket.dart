import 'package:domain/domain.dart';

import 'ports/event_repository.dart';
import 'ports/ticket_repository.dart';

const _attempts = 3;

/// Applies [change] to the stored ticket and saves it only from the status it was read in.
///
/// When another call changed the ticket in between, the save fails and the change runs again on the fresh ticket,
/// so the second of two admissions ends with TicketAlreadyUsed instead of a lost update.
/// Someone else's ticket is NotFound, so the answer does not reveal that it exists.
Future<Result<Ticket>> changeTicket(
  TicketRepository tickets,
  EventRepository events,
  TicketId id, {
  required User by,
  required Result<Ticket> Function(Ticket current) change,
  Future<void> Function(Ticket changed)? beforeSave,
}) async {
  Result<Ticket> outcome = const Failure(NotFound());
  for (var attempt = 0; attempt < _attempts; attempt++) {
    final ticket = await tickets.findTicket(id);
    if (ticket == null || !AccessPolicy.canView(by, ticket)) return const Failure(NotFound());
    if (by.role.isStaff) {
      final event = await events.findEvent(ticket.eventId);
      if (event == null || !AccessPolicy.canListEvent(by, event)) return const Failure(NotFound());
    }
    switch (change(ticket)) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        await beforeSave?.call(value);
        outcome = await tickets.save(value, from: ticket.status);
        if (outcome case Failure(error: InvalidTransition(:final from)) when from != ticket.status) continue;
        return outcome;
    }
  }
  return outcome;
}
