import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_ticketing.dart';
import 'data/seed.dart';

/// Every use case is built here once; screens and blocs only receive them.
final class AppDependencies {
  AppDependencies({
    required this.clock,
    required this.visitor,
    required EventRepository events,
    required TicketRepository tickets,
    required TicketId Function() newId,
    this.fake,
  }) : getUpcomingEvents = GetUpcomingEvents(events: events, tickets: tickets, clock: clock),
       getMyTickets = GetMyTickets(events: events, tickets: tickets, clock: clock),
       getPurchaseContext = GetPurchaseContext(events: events, tickets: tickets, clock: clock),
       reserveTickets = ReserveTickets(events: events, tickets: tickets, clock: clock, newId: newId),
       payTicket = PayTicket(tickets: tickets, clock: clock),
       cancelTicket = CancelTicket(events: events, tickets: tickets, clock: clock);

  // KT2: AppDependencies.server(...) with an HTTP adapter for both ports.
  factory AppDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 700),
  }) {
    final fake = FakeTicketing(clock: clock, latency: latency);
    return AppDependencies(clock: clock, visitor: ana, events: fake, tickets: fake, newId: fake.newId, fake: fake);
  }

  final Clock clock;
  final User visitor;
  final GetUpcomingEvents getUpcomingEvents;
  final GetMyTickets getMyTickets;
  final GetPurchaseContext getPurchaseContext;
  final ReserveTickets reserveTickets;
  final PayTicket payTicket;
  final CancelTicket cancelTicket;

  /// Only the debug menu uses it, to simulate an outage or an empty answer.
  final FakeTicketing? fake;
}
