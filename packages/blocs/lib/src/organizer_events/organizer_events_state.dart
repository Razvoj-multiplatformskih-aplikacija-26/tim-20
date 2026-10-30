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
