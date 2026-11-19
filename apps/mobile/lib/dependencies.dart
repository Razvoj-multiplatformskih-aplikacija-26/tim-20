import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_ticketing.dart';
import 'data/seed.dart';

/// Every use case is built here once; screens and blocs only receive them.
final class AppDependencies {
  AppDependencies({
    required this.clock,
    required EventRepository events,
    required TicketRepository tickets,
    required SessionRepository sessions,
    this.fake,
  }) : getUpcomingEvents = GetUpcomingEvents(events: events, clock: clock),
       getMyTickets = GetMyTickets(events: events, tickets: tickets, clock: clock),
       getPurchaseContext = GetPurchaseContext(events: events, tickets: tickets, clock: clock),
       reserveTickets = ReserveTickets(events: events, tickets: tickets, clock: clock),
       payTicket = PayTicket(events: events, tickets: tickets, clock: clock),
       cancelTicket = CancelTicket(events: events, tickets: tickets, clock: clock),
       logIn = LogIn(sessions: sessions),
       restoreSession = RestoreSession(sessions: sessions),
       logOut = LogOut(sessions: sessions),
       sessionExpirations = sessions.expirations;


  factory AppDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 700),
    bool signedIn = true,
    User user = ana,
  }) {
    final fake = FakeTicketing(clock: clock, latency: latency);
    return AppDependencies(
      clock: clock,
      events: fake,
      tickets: fake,
      sessions: InMemorySessions(user, signedIn: signedIn),
      fake: fake,
    );
  }

  final Clock clock;
  final GetUpcomingEvents getUpcomingEvents;
  final GetMyTickets getMyTickets;
  final GetPurchaseContext getPurchaseContext;
  final ReserveTickets reserveTickets;
  final PayTicket payTicket;
  final CancelTicket cancelTicket;
  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;

  /// Only the debug menu uses it, to simulate an outage or an empty answer.
  final FakeTicketing? fake;
}
