import 'event.dart';
import 'identifiers.dart';
import 'ticket.dart';

/// Active tickets of one event at [now]: reserved, paid and used.
int soldCount(List<Ticket> ticketsOfEvent, {required DateTime now}) {
  // D1
  throw UnimplementedError();
}

/// Seats still free at [now], never negative.
int remainingSeats(Event event, List<Ticket> ticketsOfEvent, {required DateTime now}) {
  // D1
  throw UnimplementedError();
}

/// Active tickets that [holder] has for [event] at [now].
int heldBy(UserId holder, EventId event, List<Ticket> tickets, {required DateTime now}) {
  // D1
  throw UnimplementedError();
}
