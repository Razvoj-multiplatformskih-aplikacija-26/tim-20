import 'event.dart';
import 'result.dart';
import 'ticket.dart';
import 'user.dart';

enum StaffAction { confirmPayment, admit, voidTicket }

Result<Ticket> confirmPayment(Ticket ticket, {required User by, required DateTime now}) {
  // F1
  throw UnimplementedError();
}

Result<Ticket> admitTicket(Ticket ticket, {required User by, required DateTime now}) {
  // F1
  throw UnimplementedError();
}

/// Actions [by] may take on [ticket] at [now].
Set<StaffAction> staffActionsFor(Ticket ticket, Event event, {required User by, required DateTime now}) {
  // F1
  throw UnimplementedError();
}
