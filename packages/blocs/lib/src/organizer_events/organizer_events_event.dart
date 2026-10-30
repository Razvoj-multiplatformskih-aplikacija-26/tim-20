part of 'organizer_events_bloc.dart';

sealed class OrganizerEventsEvent {
  const OrganizerEventsEvent();
}

final class OrganizerEventsRequested extends OrganizerEventsEvent {
  const OrganizerEventsRequested();
}
