import 'package:domain/domain.dart';

import 'ports/event_repository.dart';

final class GetOrganizerEvents {
  const GetOrganizerEvents({required this.events});

  final EventRepository events;

  /// Events [staff] works, sorted by start: an organizer their own, an usher every event.
  Future<List<Event>> call(User staff) async => [
    for (final event in await events.upcoming())
      if (AccessPolicy.canListEvent(staff, event)) event,
  ];
}
