part of 'events_bloc.dart';

sealed class EventsEvent {
  const EventsEvent();
}

final class EventsRequested extends EventsEvent {
  const EventsRequested();
}
