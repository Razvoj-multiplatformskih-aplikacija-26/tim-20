part of 'my_tickets_bloc.dart';

sealed class MyTicketsEvent {
  const MyTicketsEvent();
}

/// The session changed: a visitor signed in (their tickets load) or out (null).
final class MyTicketsVisitorChanged extends MyTicketsEvent {
  const MyTicketsVisitorChanged(this.visitor);

  final User? visitor;
}

final class MyTicketsRequested extends MyTicketsEvent {
  const MyTicketsRequested();
}

final class MyTicketsFilterChanged extends MyTicketsEvent {
  const MyTicketsFilterChanged(this.filter);

  final StatusFilter filter;
}

final class TicketPaymentRequested extends MyTicketsEvent {
  const TicketPaymentRequested(this.id);

  final TicketId id;
}

final class TicketCancellationRequested extends MyTicketsEvent {
  const TicketCancellationRequested(this.id);

  final TicketId id;
}

final class MyTicketsNoticeAcknowledged extends MyTicketsEvent {
  const MyTicketsNoticeAcknowledged();
}
