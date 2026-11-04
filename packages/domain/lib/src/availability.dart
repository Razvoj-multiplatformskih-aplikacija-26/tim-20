import 'dart:math' as math;

import 'event.dart';
import 'identifiers.dart';
import 'ticket.dart';

/// Active tickets of one event at [now]: reserved, paid and used.
int soldCount(List<Ticket> ticketsOfEvent, {required DateTime now}) =>
    ticketsOfEvent.where((ticket) => ticket.isActiveAt(now)).length;

/// Seats still free at [now], never negative.
int remainingSeats(Event event, List<Ticket> ticketsOfEvent, {required DateTime now}) =>
    math.max(0, event.capacity - soldCount(ticketsOfEvent, now: now));

/// Active tickets that [holder] has for [event] at [now].
int heldBy(UserId holder, EventId event, List<Ticket> tickets, {required DateTime now}) =>
    tickets.where((ticket) => ticket.holderId == holder && ticket.eventId == event && ticket.isActiveAt(now)).length;
