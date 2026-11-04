import 'package:meta/meta.dart';

import 'identifiers.dart';

@immutable
final class Event {
  const Event({
    required this.id,
    required this.name,
    required this.venue,
    required this.startsAt,
    required this.priceRsd,
    required this.capacity,
    required this.organizerId,
  });

  final EventId id;
  final String name;
  final String venue;

  /// UTC.
  final DateTime startsAt;

  /// Price of one ticket in dinars.
  final int priceRsd;

  /// Total number of seats.
  final int capacity;
  final UserId organizerId;

  @override
  bool operator ==(Object other) =>
      other is Event &&
      other.id == id &&
      other.name == name &&
      other.venue == venue &&
      other.startsAt == startsAt &&
      other.priceRsd == priceRsd &&
      other.capacity == capacity &&
      other.organizerId == organizerId;

  @override
  int get hashCode => Object.hash(id, name, venue, startsAt, priceRsd, capacity, organizerId);

  @override
  String toString() => 'Event($id, $name, ${startsAt.toIso8601String()})';
}
