import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'my_tickets_event.dart';
part 'my_tickets_state.dart';

// D4
final class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  MyTicketsBloc({
    required this.getMyTickets,
    required this.payTicket,
    required this.cancelTicket,
    required this.visitor,
  }) : super(const MyTicketsLoading());

  final GetMyTickets getMyTickets;
  final PayTicket payTicket;
  final CancelTicket cancelTicket;
  final User visitor;
}
