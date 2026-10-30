import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'events_event.dart';
part 'events_state.dart';

// D4
final class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc(this.getUpcomingEvents) : super(const EventsLoading());

  final GetUpcomingEvents getUpcomingEvents;
}
