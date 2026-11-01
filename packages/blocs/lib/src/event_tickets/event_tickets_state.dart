part of 'event_tickets_bloc.dart';

sealed class EventTicketsState extends Equatable {
  const EventTicketsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class EventTicketsLoading extends EventTicketsState {
  const EventTicketsLoading();
}

final class EventTicketsFailure extends EventTicketsState {
  const EventTicketsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'EventTicketsFailure($cause)';
}

final class EventTicketsNotFound extends EventTicketsState {
  const EventTicketsNotFound();
}

final class EventTicketsEmpty extends EventTicketsState {
  const EventTicketsEmpty(this.event);

  final Event event;

  @override
  List<Object?> get props => [event];
}

final class EventTicketsLoaded extends EventTicketsState {
  const EventTicketsLoaded({
    required this.data,
    this.filter = StatusFilter.all,
    this.cursor = 0,
    this.selectedId,
    this.inFlightId,
    this.notice,
  });

  final EventTickets data;
  final StatusFilter filter;

  /// Index into [visible].
  final int cursor;
  final TicketId? selectedId;
  final TicketId? inFlightId;
  final EventTicketsNotice? notice;

  @override
  List<Object?> get props => [data, filter, cursor, selectedId, inFlightId, notice];

  List<Ticket> get visible => [
    for (final ticket in data.tickets)
      if (filter.matches(ticket.status)) ticket,
  ];

  Ticket? get selected => selectedId == null ? null : data.tickets.where((t) => t.id == selectedId).firstOrNull;

  Ticket? get atCursor {
    final tickets = visible;
    return cursor >= 0 && cursor < tickets.length ? tickets[cursor] : null;
  }

  bool get isBusy => inFlightId != null;

  Set<StaffAction> actionsFor(TicketId id) => data.actions[id] ?? const {};

  EventTicketsLoaded copyWith({
    EventTickets? data,
    StatusFilter? filter,
    int? cursor,
    TicketId? selectedId,
    bool clearSelection = false,
    TicketId? inFlightId,
    bool clearInFlight = false,
    EventTicketsNotice? notice,
    bool clearNotice = false,
  }) {
    return EventTicketsLoaded(
      data: data ?? this.data,
      filter: filter ?? this.filter,
      cursor: cursor ?? this.cursor,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      inFlightId: clearInFlight ? null : (inFlightId ?? this.inFlightId),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  String toString() => [
    'EventTicketsLoaded(${data.tickets.length} tickets',
    if (filter != StatusFilter.all) ', ${filter.name}',
    ', cursor $cursor',
    if (selectedId case final id?) ', selected ${id.value}',
    if (inFlightId case final id?) ', in flight ${id.value}',
    if (notice case final notice?) ', ${notice.runtimeType}',
    ')',
  ].join();
}

sealed class EventTicketsNotice extends Equatable {
  const EventTicketsNotice();

  @override
  List<Object?> get props => const [];
}

final class StaffActionSucceeded extends EventTicketsNotice {
  const StaffActionSucceeded(this.ticket, this.action);

  final Ticket ticket;
  final StaffAction action;

  @override
  List<Object?> get props => [ticket, action];
}

final class StaffActionRejected extends EventTicketsNotice {
  const StaffActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class StaffActionFailed extends EventTicketsNotice {
  const StaffActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
