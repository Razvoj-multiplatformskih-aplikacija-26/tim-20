import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_box_office.dart';
import 'data/seed.dart';

/// Everything the screens need, built once. Another implementation of the ports changes only this file.
final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required this.staff,
    required EventRepository events,
    required TicketRepository tickets,
    this.fake,
  }) : getOrganizerEvents = GetOrganizerEvents(events: events),
       getEventTickets = GetEventTickets(events: events, tickets: tickets, clock: clock),
       confirmPayment = ConfirmPayment(tickets: tickets, clock: clock),
       admitTicket = AdmitTicket(tickets: tickets, clock: clock),
       voidTicket = VoidTicket(events: events, tickets: tickets, clock: clock);

  factory BackofficeDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 700),
  }) {
    final fake = FakeBoxOffice(clock: clock, latency: latency);
    return BackofficeDependencies(clock: clock, staff: organizer, events: fake, tickets: fake, fake: fake);
  }

  final Clock clock;
  final User staff;
  final GetOrganizerEvents getOrganizerEvents;
  final GetEventTickets getEventTickets;
  final ConfirmPayment confirmPayment;
  final AdmitTicket admitTicket;
  final VoidTicket voidTicket;

  /// Only for the debug menu; null with a real implementation.
  final FakeBoxOffice? fake;
}
