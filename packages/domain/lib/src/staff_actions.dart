import 'access_policy.dart';
import 'errors.dart';
import 'event.dart';
import 'result.dart';
import 'ticket.dart';
import 'ticket_status.dart';
import 'user.dart';

enum StaffAction { confirmPayment, admit, voidTicket }

Result<Ticket> confirmPayment(Ticket ticket, {required User by, required DateTime now}) {
  if (!AccessPolicy.canConfirm(by)) return const Failure(NotAllowed());
  final current = effectiveStatus(ticket, now: now);
  if (current is Expired) return const Failure(ReservationExpired());
  final next = Paid(paidAt: now.toUtc(), confirmedBy: by.id);
  if (!canTransition(current, next)) return Failure(InvalidTransition(from: current, to: next));
  return Success(ticket.copyWith(status: next));
}

Result<Ticket> admitTicket(Ticket ticket, {required User by, required DateTime now}) {
  if (!AccessPolicy.canAdmit(by)) return const Failure(NotAllowed());
  final current = effectiveStatus(ticket, now: now);
  if (current is Used) return const Failure(TicketAlreadyUsed());
  final next = Used(scannedAt: now.toUtc(), scannedBy: by.id);
  if (!canTransition(current, next)) return Failure(InvalidTransition(from: current, to: next));
  return Success(ticket.copyWith(status: next));
}

/// Actions [by] may take on [ticket] at [now]: exactly those whose rule would succeed.
Set<StaffAction> staffActionsFor(Ticket ticket, Event event, {required User by, required DateTime now}) => {
  if (confirmPayment(ticket, by: by, now: now).isSuccess) StaffAction.confirmPayment,
  if (admitTicket(ticket, by: by, now: now).isSuccess) StaffAction.admit,
  if (_mayVoid(ticket, event, by: by, now: now)) StaffAction.voidTicket,
};

// The checks cancelTicket makes for staff, until the visitor rules call it directly.
bool _mayVoid(Ticket ticket, Event event, {required User by, required DateTime now}) {
  if (!by.role.isStaff || !AccessPolicy.canCancel(by, ticket)) return false;
  final current = effectiveStatus(ticket, now: now);
  return canTransition(current, Cancelled(at: now.toUtc(), by: by.id)) && now.isBefore(event.startsAt);
}
