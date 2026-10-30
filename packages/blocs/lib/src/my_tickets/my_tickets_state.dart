part of 'my_tickets_bloc.dart';

sealed class MyTicketsState extends Equatable {
  const MyTicketsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyTicketsLoading extends MyTicketsState {
  const MyTicketsLoading();
}

final class MyTicketsFailure extends MyTicketsState {
  const MyTicketsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'MyTicketsFailure($cause)';
}

/// The visitor has no tickets at all; a filter that matches nothing is still [MyTicketsLoaded].
final class MyTicketsEmpty extends MyTicketsState {
  const MyTicketsEmpty();
}

final class MyTicketsLoaded extends MyTicketsState {
  const MyTicketsLoaded({required this.tickets, this.filter = StatusFilter.all, this.inFlightId, this.notice});

  final List<OwnedTicket> tickets;
  final StatusFilter filter;
  final TicketId? inFlightId;
  final MyTicketsNotice? notice;

  @override
  List<Object?> get props => [tickets, filter, inFlightId, notice];

  @override
  String toString() => [
    'MyTicketsLoaded(${tickets.length} tickets, ${filter.name}',
    if (inFlightId case final id?) ', in flight ${id.value}',
    if (notice case final notice?) ', ${notice.runtimeType}',
    ')',
  ].join();

  List<OwnedTicket> get visible => [
    for (final owned in tickets)
      if (filter.matches(owned.ticket.status)) owned,
  ];

  OwnedTicket? byId(TicketId id) {
    for (final owned in tickets) {
      if (owned.ticket.id == id) return owned;
    }
    return null;
  }

  bool get isBusy => inFlightId != null;

  /// [inFlightId] and [notice] are cleared unless given, since both last for one step only.
  MyTicketsLoaded copyWith({StatusFilter? filter, TicketId? inFlightId, MyTicketsNotice? notice}) =>
      MyTicketsLoaded(tickets: tickets, filter: filter ?? this.filter, inFlightId: inFlightId, notice: notice);
}

sealed class MyTicketsNotice extends Equatable {
  const MyTicketsNotice();

  @override
  List<Object?> get props => const [];
}

final class TicketPaid extends MyTicketsNotice {
  const TicketPaid(this.ticket);

  final Ticket ticket;

  @override
  List<Object?> get props => [ticket];
}

final class TicketCancelled extends MyTicketsNotice {
  const TicketCancelled(this.ticket);

  final Ticket ticket;

  @override
  List<Object?> get props => [ticket];
}

final class TicketActionRejected extends MyTicketsNotice {
  const TicketActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class TicketActionFailed extends MyTicketsNotice {
  const TicketActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
