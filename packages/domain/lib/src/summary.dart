import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'event.dart';
import 'ticket.dart';

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
  // F1
  throw UnimplementedError();
}
