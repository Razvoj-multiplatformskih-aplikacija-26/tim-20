import 'access_policy.dart';
import 'availability.dart';
import 'errors.dart';
import 'event.dart';
import 'identifiers.dart';
import 'result.dart';
import 'rules.dart';
import 'ticket.dart';
import 'ticket_quantity.dart';
import 'ticket_status.dart';
import 'user.dart';

enum VisitorAction { pay, cancel }

/// New reservations for [by], one ticket per seat, each holding a seat for [reservationHold].
///
/// The seat count depends on the tickets of other visitors, so the server repeats this check.
Result<List<Ticket>> reserveTickets({
  required Event event,
  required List<Ticket> ticketsOfEvent,
  required User by,
  required int quantity,
  required DateTime now,
  required TicketId Function() newId,
}) {
  if (!AccessPolicy.canBuy(by)) return const Failure(NotAllowed());
  if (!now.isBefore(event.startsAt)) return const Failure(EventAlreadyStarted());

  final alreadyHeld = heldBy(by.id, event.id, ticketsOfEvent, now: now);
  final parsed = TicketQuantity.parse(quantity, alreadyHeld: alreadyHeld);
  if (parsed case Failure(:final error)) return Failure(error);

  final remaining = remainingSeats(event, ticketsOfEvent, now: now);
  if (quantity > remaining) return Failure(NotEnoughSeats(remaining));

  final status = Reserved(expiresAt: now.add(reservationHold));
  return Success([
    for (var i = 0; i < quantity; i++) _newTicket(newId(), event: event, holder: by, status: status, now: now),
  ]);
}

Ticket _newTicket(
  TicketId id, {
  required Event event,
  required User holder,
  required Reserved status,
  required DateTime now,
}) {
  return Ticket(
    id: id,
    eventId: event.id,
    holderId: holder.id,
    holderName: holder.name,
    status: status,
    createdAt: now,
    code: 'T20-${id.value}',
  );
}

Result<Ticket> payTicket(Ticket ticket, {required User by, required DateTime now}) {
  if (!AccessPolicy.canPay(by, ticket)) return const Failure(NotAllowed());

  final current = effectiveStatus(ticket, now: now);
  if (current is Expired) return const Failure(ReservationExpired());

  final next = Paid(paidAt: now);
  if (!canTransition(current, next)) return Failure(InvalidTransition(from: current, to: next));
  return Success(ticket.copyWith(status: next));
}

/// A visitor cancels at the latest [cancellationNotice] before the start; an organizer has no notice.
Result<Ticket> cancelTicket(Ticket ticket, Event event, {required User by, required DateTime now, String reason = ''}) {
  if (!AccessPolicy.canCancel(by, ticket)) return const Failure(NotAllowed());

  final current = effectiveStatus(ticket, now: now);
  final next = Cancelled(at: now, by: by.id, reason: reason);
  if (!canTransition(current, next)) return Failure(InvalidTransition(from: current, to: next));

  if (!now.isBefore(event.startsAt)) return const Failure(EventAlreadyStarted());
  if (by.role == Role.visitor && now.isAfter(event.startsAt.subtract(cancellationNotice))) {
    return const Failure(CancellationTooLate());
  }
  return Success(ticket.copyWith(status: next));
}

/// Actions [by] may take on [ticket] at [now].
Set<VisitorAction> visitorActionsFor(Ticket ticket, Event event, {required User by, required DateTime now}) => {
  if (payTicket(ticket, by: by, now: now).isSuccess) VisitorAction.pay,
  if (cancelTicket(ticket, event, by: by, now: now).isSuccess) VisitorAction.cancel,
};
