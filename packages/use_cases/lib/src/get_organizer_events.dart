import 'package:domain/domain.dart';

import 'ports/event_repository.dart';

final class GetOrganizerEvents {
  const GetOrganizerEvents({required this.events});

  final EventRepository events;

  /// Events of [organizer], sorted by start.
  Future<List<Event>> call(User organizer) async => [
    for (final event in await events.upcoming())
      if (event.organizerId == organizer.id) event,
  ];
}
