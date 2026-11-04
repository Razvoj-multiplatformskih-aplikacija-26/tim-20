import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'events_event.dart';
part 'events_state.dart';

final class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc(this.getUpcomingEvents) : super(const EventsLoading()) {
    on<EventsRequested>((event, emit) async {
      emit(const EventsLoading());
      try {
        final events = await getUpcomingEvents();
        emit(events.isEmpty ? const EventsEmpty() : EventsLoaded(events));
      } on Exception catch (cause) {
        emit(EventsFailure(cause));
      }
    });
  }

  final GetUpcomingEvents getUpcomingEvents;
}
