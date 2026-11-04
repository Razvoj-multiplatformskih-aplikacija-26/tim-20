import 'package:domain/domain.dart';

abstract interface class EventRepository {
  /// Every event, sorted by start. The repository does not read the clock, so past events are filtered by use cases.
  Future<List<Event>> upcoming();

  Future<Event?> findEvent(EventId id);
}
