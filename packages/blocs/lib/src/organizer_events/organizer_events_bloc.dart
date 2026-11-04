import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'organizer_events_event.dart';
part 'organizer_events_state.dart';

final class OrganizerEventsBloc extends Bloc<OrganizerEventsEvent, OrganizerEventsState> {
  OrganizerEventsBloc(this.getOrganizerEvents, {required this.organizer}) : super(const OrganizerEventsLoading()) {
    on<OrganizerEventsRequested>((event, emit) async {
      emit(const OrganizerEventsLoading());
      try {
        final events = await getOrganizerEvents(organizer);
        emit(events.isEmpty ? const OrganizerEventsEmpty() : OrganizerEventsLoaded(events));
      } on Exception catch (cause) {
        emit(OrganizerEventsFailure(cause));
      }
    });
  }

  final GetOrganizerEvents getOrganizerEvents;
  final User organizer;
}
