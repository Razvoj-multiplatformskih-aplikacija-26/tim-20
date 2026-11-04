part of 'my_tickets_bloc.dart';

sealed class MyTicketsEvent {
  const MyTicketsEvent();
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
