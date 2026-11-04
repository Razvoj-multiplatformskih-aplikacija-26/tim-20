part of 'events_bloc.dart';

sealed class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class EventsLoading extends EventsState {
  const EventsLoading();
}

final class EventsFailure extends EventsState {
  const EventsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'EventsFailure($cause)';
}

final class EventsEmpty extends EventsState {
  const EventsEmpty();
}

final class EventsLoaded extends EventsState {
  const EventsLoaded(this.events);

  final List<EventListing> events;

  @override
  List<Object?> get props => [events];

  @override
  String toString() => 'EventsLoaded(${events.length} events)';
}
