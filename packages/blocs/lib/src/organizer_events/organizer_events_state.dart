part of 'organizer_events_bloc.dart';

sealed class OrganizerEventsState extends Equatable {
  const OrganizerEventsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class OrganizerEventsLoading extends OrganizerEventsState {
  const OrganizerEventsLoading();
}

final class OrganizerEventsFailure extends OrganizerEventsState {
  const OrganizerEventsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'OrganizerEventsFailure($cause)';
}

final class OrganizerEventsEmpty extends OrganizerEventsState {
  const OrganizerEventsEmpty();
}

final class OrganizerEventsLoaded extends OrganizerEventsState {
  const OrganizerEventsLoaded(this.events);

  final List<Event> events;

  @override
  List<Object?> get props => [events];

  @override
  String toString() => 'OrganizerEventsLoaded(${events.length} events)';
}
