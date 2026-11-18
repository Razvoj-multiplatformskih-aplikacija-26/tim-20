import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import '../status_filter.dart';

part 'my_tickets_event.dart';
part 'my_tickets_state.dart';

final class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  MyTicketsBloc({required this.getMyTickets, required this.payTicket, required this.cancelTicket, required this.clock})
    : super(const MyTicketsSignedOut()) {
    on<MyTicketsVisitorChanged>((event, emit) async {
      _visitor = event.visitor;
      if (event.visitor == null) return emit(const MyTicketsSignedOut());
      emit(const MyTicketsLoading());
      await _reload(emit);
    });
    on<MyTicketsRequested>((event, emit) async {
      if (_visitor == null) return;
      emit(const MyTicketsLoading());
      await _reload(emit);
    });
    on<MyTicketsFilterChanged>((event, emit) {
      final current = state;
      if (current is MyTicketsLoaded) emit(current.withFilter(event.filter));
    });
    on<TicketPaymentRequested>(
      (event, emit) => _act(event.id, emit, (visitor) => payTicket(id: event.id, by: visitor), TicketPaid.new),
    );
    on<TicketCancellationRequested>(
      (event, emit) => _act(event.id, emit, (visitor) => cancelTicket(id: event.id, by: visitor), TicketCancelled.new),
    );
    on<MyTicketsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyTicketsLoaded && current.notice != null) emit(current.withNotice(null));
    });
  }

  final GetMyTickets getMyTickets;
  final PayTicket payTicket;
  final CancelTicket cancelTicket;
  final Clock clock;

  /// The signed-in visitor comes from the session, so the bloc only remembers whose tickets it shows.
  User? _visitor;

  /// The filter may change while an action runs, so the result is built on the latest state.
  MyTicketsLoaded _latest(MyTicketsLoaded fallback) {
    final current = state;
    return current is MyTicketsLoaded ? current : fallback;
  }

  /// One action at a time: while a ticket is in flight, other actions are ignored.
  /// A rejection reloads the tickets first, so a late client sees what the server decided.
  Future<void> _act(
    TicketId id,
    Emitter<MyTicketsState> emit,
    Future<Result<Ticket>> Function(User visitor) action,
    MyTicketsNotice Function(Ticket) succeeded,
  ) async {
    final current = state;
    final visitor = _visitor;
    if (visitor == null || current is! MyTicketsLoaded || current.isBusy) return;
    emit(current.withInFlight(id));
    final Result<Ticket> result;
    try {
      result = await action(visitor);
    } on Exception catch (cause) {
      if (visitor != _visitor) return;
      emit(_latest(current).withNotice(TicketActionFailed(cause)));
      return;
    }
    if (visitor != _visitor) return;
    final notice = switch (result) {
      Success(:final value) => succeeded(value),
      Failure(:final error) => TicketActionRejected(error),
    };
    await _reload(emit, filter: _latest(current).filter, notice: notice);
  }

  Future<void> _reload(
    Emitter<MyTicketsState> emit, {
    StatusFilter filter = StatusFilter.all,
    MyTicketsNotice? notice,
  }) async {
    final visitor = _visitor;
    if (visitor == null) return;
    try {
      final loadedAt = clock.now();
      final tickets = await getMyTickets(visitor);
      if (visitor != _visitor) return;
      emit(
        tickets.isEmpty
            ? const MyTicketsEmpty()
            : MyTicketsLoaded(tickets: tickets, loadedAt: loadedAt, filter: filter, notice: notice),
      );
    } on Exception catch (cause) {
      if (visitor != _visitor) return;
      emit(MyTicketsFailure(cause));
    }
  }
}
