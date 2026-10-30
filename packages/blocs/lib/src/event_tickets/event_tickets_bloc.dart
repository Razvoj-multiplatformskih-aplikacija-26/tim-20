import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'event_tickets_event.dart';
part 'event_tickets_state.dart';

// F3
final class EventTicketsBloc extends Bloc<EventTicketsEvent, EventTicketsState> {
  EventTicketsBloc({
    required this.getEventTickets,
    required this.confirmPayment,
    required this.admitTicket,
    required this.voidTicket,
    required this.staff,
  }) : super(const EventTicketsLoading());

  final GetEventTickets getEventTickets;
  final ConfirmPayment confirmPayment;
  final AdmitTicket admitTicket;
  final VoidTicket voidTicket;
  final User staff;
}
