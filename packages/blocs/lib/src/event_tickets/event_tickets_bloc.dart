import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import '../status_filter.dart';

part 'event_tickets_event.dart';
part 'event_tickets_state.dart';

final class EventTicketsBloc extends Bloc<EventTicketsEvent, EventTicketsState> {
  EventTicketsBloc({
    required this.getEventTickets,
    required this.confirmPayment,
    required this.admitTicket,
    required this.voidTicket,
    required this.staff,
  }) : super(const EventTicketsLoading()) {
    on<EventTicketsRequested>((event, emit) => _load(emit, event.eventId, selectedId: event.selectedId));
    on<EventTicketsRefreshed>((event, emit) => _refresh(emit));
    on<TicketSelected>((event, emit) => _select(emit, event.id));
    on<TicketCursorMoved>((event, emit) {
      final current = state;
      if (current is EventTicketsLoaded) emit(_settle(current.copyWith(cursor: current.cursor + event.delta)));
    });
    on<TicketCursorActivated>((event, emit) {
      final current = state;
      if (current is EventTicketsLoaded) _select(emit, current.atCursor?.id);
    });
    on<TicketStatusFilterChanged>((event, emit) {
      final current = state;
      if (current is EventTicketsLoaded) emit(_settle(current.copyWith(filter: event.filter)));
    });
    on<PaymentConfirmationRequested>(
      (event, emit) => _act(emit, event.id, StaffAction.confirmPayment, () => confirmPayment(id: event.id, by: staff)),
    );
    on<TicketAdmissionRequested>(
      (event, emit) => _act(emit, event.id, StaffAction.admit, () => admitTicket(id: event.id, by: staff)),
    );
    on<TicketVoidRequested>(
      (event, emit) =>
          _act(emit, event.id, StaffAction.voidTicket, () => voidTicket(id: event.id, by: staff, reason: event.reason)),
    );
    on<EventTicketsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is EventTicketsLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final GetEventTickets getEventTickets;
  final ConfirmPayment confirmPayment;
  final AdmitTicket admitTicket;
  final VoidTicket voidTicket;
  final User staff;
  EventId? _eventId;

  // Every load and action takes a number, so a result that comes back after a newer request is dropped.
  int _request = 0;

  Future<void> _load(Emitter<EventTicketsState> emit, EventId eventId, {TicketId? selectedId}) async {
    final request = ++_request;
    _eventId = eventId;
    emit(const EventTicketsLoading());
    try {
      final data = await getEventTickets(eventId: eventId, staff: staff);
      if (request != _request) return;
      if (data == null) return emit(const EventTicketsNotFound());
      if (data.tickets.isEmpty) return emit(EventTicketsEmpty(data.event));
      emit(_settle(EventTicketsLoaded(data: data, selectedId: selectedId), followSelection: true));
    } on Exception catch (cause) {
      if (request != _request) return;
      emit(EventTicketsFailure(cause));
    }
  }

  // Reloads without passing through loading, so the table keeps its filter, selection and cursor.
  Future<void> _refresh(Emitter<EventTicketsState> emit) async {
    final eventId = _eventId;
    if (state is! EventTicketsLoaded || eventId == null) return;
    final request = ++_request;
    try {
      final data = await getEventTickets(eventId: eventId, staff: staff);
      if (data != null) _finish(emit, request, data: data);
    } on Exception catch (cause) {
      _finish(emit, request, notice: StaffActionFailed(cause));
    }
  }

  Future<void> _act(
    Emitter<EventTicketsState> emit,
    TicketId id,
    StaffAction action,
    Future<Result<Ticket>> Function() call,
  ) async {
    final current = state;
    final eventId = _eventId;
    if (current is! EventTicketsLoaded || current.isBusy || eventId == null) return;
    final request = ++_request;
    emit(current.copyWith(inFlightId: id, clearNotice: true));
    try {
      final result = await call();
      // Reload after a rejection too: the rule may have refused because the ticket changed meanwhile.
      final data = await getEventTickets(eventId: eventId, staff: staff);
      final notice = switch (result) {
        Failure(:final error) => StaffActionRejected(error),
        Success(:final value) => StaffActionSucceeded(value, action),
      };
      _finish(emit, request, data: data, notice: notice);
    } on Exception catch (cause) {
      _finish(emit, request, notice: StaffActionFailed(cause));
    }
  }

  // Builds on the state as it is now, not as it was before the await, so the user's moves meanwhile stay.
  void _finish(Emitter<EventTicketsState> emit, int request, {EventTickets? data, EventTicketsNotice? notice}) {
    final latest = state;
    if (request != _request || latest is! EventTicketsLoaded) return;
    emit(_settle(latest.copyWith(data: data, notice: notice, clearInFlight: true)));
  }

  void _select(Emitter<EventTicketsState> emit, TicketId? id) {
    final current = state;
    if (current is! EventTicketsLoaded) return;
    emit(_settle(current.copyWith(selectedId: id, clearSelection: id == null), followSelection: true));
  }

  // A selection the filter hides is closed, and the cursor always points at a visible row.
  EventTicketsLoaded _settle(EventTicketsLoaded loaded, {bool followSelection = false}) {
    final visible = loaded.visible;
    final selectedIndex = visible.indexWhere((t) => t.id == loaded.selectedId);
    final cursor = followSelection && selectedIndex >= 0 ? selectedIndex : loaded.cursor;
    return loaded.copyWith(
      cursor: visible.isEmpty ? 0 : cursor.clamp(0, visible.length - 1),
      clearSelection: selectedIndex < 0,
    );
  }
}
