import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'event.dart';
import 'ticket.dart';
import 'ticket_status.dart';

@immutable
final class TicketSummary {
  const TicketSummary({
    required this.capacity,
    required this.reserved,
    required this.paid,
    required this.used,
    required this.cancelled,
    required this.expired,
  });

  final int capacity;
  final int reserved;
  final int paid;
  final int used;
  final int cancelled;
  final int expired;

  int get sold => reserved + paid + used;

  int get remaining => math.max(0, capacity - sold);

  /// From 0 to 1.
  double get occupancy => capacity == 0 ? 0 : sold / capacity;

  int get entered => used;

  @override
  bool operator ==(Object other) =>
      other is TicketSummary &&
      other.capacity == capacity &&
      other.reserved == reserved &&
      other.paid == paid &&
      other.used == used &&
      other.cancelled == cancelled &&
      other.expired == expired;

  @override
  int get hashCode => Object.hash(capacity, reserved, paid, used, cancelled, expired);

  @override
  String toString() => 'TicketSummary(sold $sold of $capacity, entered $entered)';
}

/// Counts the tickets of [event] by their status at [now].
TicketSummary summarize(Event event, List<Ticket> ticketsOfEvent, {required DateTime now}) {
  var reserved = 0, paid = 0, used = 0, cancelled = 0, expired = 0;
  for (final ticket in ticketsOfEvent) {
    switch (effectiveStatus(ticket, now: now)) {
      case Reserved():
        reserved++;
      case Paid():
        paid++;
      case Used():
        used++;
      case Cancelled():
        cancelled++;
      case Expired():
        expired++;
    }
  }
  return TicketSummary(
    capacity: event.capacity,
    reserved: reserved,
    paid: paid,
    used: used,
    cancelled: cancelled,
    expired: expired,
  );
}
