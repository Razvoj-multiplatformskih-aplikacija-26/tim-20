import 'package:domain/domain.dart';

abstract interface class EventRepository {
  /// Every event, sorted by start. The repository does not read the clock, so past events are filtered by use cases.
  Future<List<Event>> upcoming();

  Future<Event?> findEvent(EventId id);

  /// Free seats at [now], counted where every ticket is visible, so a visitor never receives the tickets of others.
  Future<int> remainingSeats(EventId id, {required DateTime now});
}
