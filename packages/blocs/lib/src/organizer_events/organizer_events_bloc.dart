import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'organizer_events_event.dart';
part 'organizer_events_state.dart';

// F3
final class OrganizerEventsBloc extends Bloc<OrganizerEventsEvent, OrganizerEventsState> {
  OrganizerEventsBloc(this.getOrganizerEvents, {required this.organizer}) : super(const OrganizerEventsLoading());

  final GetOrganizerEvents getOrganizerEvents;
  final User organizer;
}
