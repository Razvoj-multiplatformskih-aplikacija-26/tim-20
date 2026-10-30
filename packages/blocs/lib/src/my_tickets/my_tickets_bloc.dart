import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import '../status_filter.dart';

part 'my_tickets_event.dart';
part 'my_tickets_state.dart';

final class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  MyTicketsBloc({
    required this.getMyTickets,
    required this.payTicket,
    required this.cancelTicket,
    required this.visitor,
    required this.clock,
  }) : super(const MyTicketsLoading()) {
    on<MyTicketsRequested>((event, emit) async {
      emit(const MyTicketsLoading());
      await _reload(emit);
    });
    on<MyTicketsFilterChanged>((event, emit) {
      final current = state;
      if (current is MyTicketsLoaded) emit(current.withFilter(event.filter));
    });
    on<TicketPaymentRequested>(
      (event, emit) => _act(event.id, emit, () => payTicket(id: event.id, by: visitor), TicketPaid.new),
    );
    on<TicketCancellationRequested>(
      (event, emit) => _act(event.id, emit, () => cancelTicket(id: event.id, by: visitor), TicketCancelled.new),
    );
    on<MyTicketsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyTicketsLoaded && current.notice != null) emit(current.withNotice(null));
    });
  }

  final GetMyTickets getMyTickets;
  final PayTicket payTicket;
  final CancelTicket cancelTicket;
  final User visitor;
  final Clock clock;

  /// The filter may change while an action runs, so the result is built on the latest state.
  MyTicketsLoaded _latest(MyTicketsLoaded fallback) {
    final current = state;
    return current is MyTicketsLoaded ? current : fallback;
  }

  /// One action at a time: while a ticket is in flight, other actions are ignored.
  Future<void> _act(
    TicketId id,
    Emitter<MyTicketsState> emit,
    Future<Result<Ticket>> Function() action,
    MyTicketsNotice Function(Ticket) succeeded,
  ) async {
    final current = state;
    if (current is! MyTicketsLoaded || current.isBusy) return;
    emit(current.withInFlight(id));
    final Result<Ticket> result;
    try {
      result = await action();
    } on Exception catch (cause) {
      emit(_latest(current).withNotice(TicketActionFailed(cause)));
      return;
    }
    switch (result) {
      case Success(:final value):
        await _reload(emit, filter: _latest(current).filter, notice: succeeded(value));
      case Failure(:final error):
        emit(_latest(current).withNotice(TicketActionRejected(error)));
    }
  }

  Future<void> _reload(
    Emitter<MyTicketsState> emit, {
    StatusFilter filter = StatusFilter.all,
    MyTicketsNotice? notice,
  }) async {
    try {
      final loadedAt = clock.now();
      final tickets = await getMyTickets(visitor);
      emit(
        tickets.isEmpty
            ? const MyTicketsEmpty()
            : MyTicketsLoaded(tickets: tickets, loadedAt: loadedAt, filter: filter, notice: notice),
      );
    } on Exception catch (cause) {
      emit(MyTicketsFailure(cause));
    }
  }
}
