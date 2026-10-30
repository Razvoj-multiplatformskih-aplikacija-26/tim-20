part of 'event_tickets_bloc.dart';

sealed class EventTicketsEvent {
  const EventTicketsEvent();
}

final class EventTicketsRequested extends EventTicketsEvent {
  const EventTicketsRequested(this.eventId, {this.selectedId});

  final EventId eventId;
  final TicketId? selectedId;
}
