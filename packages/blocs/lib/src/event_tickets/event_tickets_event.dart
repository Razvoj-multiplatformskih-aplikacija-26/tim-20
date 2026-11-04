part of 'event_tickets_bloc.dart';

sealed class EventTicketsEvent {
  const EventTicketsEvent();
}

final class EventTicketsRequested extends EventTicketsEvent {
  const EventTicketsRequested(this.eventId, {this.selectedId});

  final EventId eventId;
  final TicketId? selectedId;
}

final class EventTicketsRefreshed extends EventTicketsEvent {
  const EventTicketsRefreshed();
}

final class TicketSelected extends EventTicketsEvent {
  const TicketSelected(this.id);

  final TicketId? id;
}

final class TicketCursorMoved extends EventTicketsEvent {
  const TicketCursorMoved(this.delta);

  final int delta;
}

final class TicketCursorActivated extends EventTicketsEvent {
  const TicketCursorActivated();
}

final class TicketStatusFilterChanged extends EventTicketsEvent {
  const TicketStatusFilterChanged(this.filter);

  final StatusFilter filter;
}

final class PaymentConfirmationRequested extends EventTicketsEvent {
  const PaymentConfirmationRequested(this.id);

  final TicketId id;
}

final class TicketAdmissionRequested extends EventTicketsEvent {
  const TicketAdmissionRequested(this.id);

  final TicketId id;
}

final class TicketVoidRequested extends EventTicketsEvent {
  const TicketVoidRequested(this.id, {required this.reason});

  final TicketId id;
  final String reason;
}

final class EventTicketsNoticeAcknowledged extends EventTicketsEvent {
  const EventTicketsNoticeAcknowledged();
}
