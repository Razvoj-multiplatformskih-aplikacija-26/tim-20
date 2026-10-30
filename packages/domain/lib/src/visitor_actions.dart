import 'event.dart';
import 'identifiers.dart';
import 'result.dart';
import 'ticket.dart';
import 'user.dart';

enum VisitorAction { pay, cancel }

Result<List<Ticket>> reserveTickets({
  required Event event,
  required List<Ticket> ticketsOfEvent,
  required User by,
  required int quantity,
  required DateTime now,
  required TicketId Function() newId,
}) {
  // D1
  throw UnimplementedError();
}

Result<Ticket> payTicket(Ticket ticket, {required User by, required DateTime now}) {
  // D1
  throw UnimplementedError();
}

Result<Ticket> cancelTicket(Ticket ticket, Event event, {required User by, required DateTime now, String reason = ''}) {
  // D1
  throw UnimplementedError();
}

/// Actions [by] may take on [ticket] at [now].
Set<VisitorAction> visitorActionsFor(Ticket ticket, Event event, {required User by, required DateTime now}) {
  // D1
  throw UnimplementedError();
}
