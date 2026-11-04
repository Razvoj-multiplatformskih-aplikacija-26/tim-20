import 'package:collection/collection.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

// Use cases return tickets with the effective status already applied: ticket.copyWith(status: effectiveStatus(...)).

@immutable
final class EventListing {
  const EventListing({required this.event, required this.remaining});

  final Event event;
  final int remaining;

  @override
  bool operator ==(Object other) => other is EventListing && other.event == event && other.remaining == remaining;

  @override
  int get hashCode => Object.hash(event, remaining);

  @override
  String toString() => 'EventListing(${event.name}, $remaining left)';
}

@immutable
final class OwnedTicket {
  const OwnedTicket({required this.ticket, required this.event, required this.actions});

  final Ticket ticket;
  final Event event;
  final Set<VisitorAction> actions;

  @override
  bool operator ==(Object other) =>
      other is OwnedTicket &&
      other.ticket == ticket &&
      other.event == event &&
      const SetEquality<VisitorAction>().equals(other.actions, actions);

  @override
  int get hashCode => Object.hash(ticket, event, Object.hashAllUnordered(actions));

  @override
  String toString() => 'OwnedTicket(${ticket.id}, ${event.name}, $actions)';
}

@immutable
final class PurchaseContext {
  const PurchaseContext({required this.event, required this.remaining, required this.alreadyHeld});

  final Event event;
  final int remaining;
  final int alreadyHeld;

  @override
  bool operator ==(Object other) =>
      other is PurchaseContext &&
      other.event == event &&
      other.remaining == remaining &&
      other.alreadyHeld == alreadyHeld;

  @override
  int get hashCode => Object.hash(event, remaining, alreadyHeld);

  @override
  String toString() => 'PurchaseContext(${event.name}, $remaining left, $alreadyHeld held)';
}

@immutable
final class EventTickets {
  const EventTickets({required this.event, required this.tickets, required this.summary, required this.actions});

  final Event event;
  final List<Ticket> tickets;
  final TicketSummary summary;
  final Map<TicketId, Set<StaffAction>> actions;

  @override
  bool operator ==(Object other) =>
      other is EventTickets &&
      other.event == event &&
      const ListEquality<Ticket>().equals(other.tickets, tickets) &&
      other.summary == summary &&
      const MapEquality<TicketId, Set<StaffAction>>(values: SetEquality<StaffAction>()).equals(other.actions, actions);

  @override
  int get hashCode => Object.hash(event, Object.hashAll(tickets), summary, actions.length);

  @override
  String toString() => 'EventTickets(${event.name}, ${tickets.length} tickets)';
}
