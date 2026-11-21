import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_box_office.dart';
import 'data/seed.dart';

/// Everything the screens need, built once. Another implementation of the ports changes only this file.
final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required EventRepository events,
    required TicketRepository tickets,
    required SessionRepository sessions,
    this.fake,
  }) : getOrganizerEvents = GetOrganizerEvents(events: events),
       getEventTickets = GetEventTickets(events: events, tickets: tickets, clock: clock),
       confirmPayment = ConfirmPayment(tickets: tickets, clock: clock),
       admitTicket = AdmitTicket(tickets: tickets, clock: clock),
       voidTicket = VoidTicket(events: events, tickets: tickets, clock: clock),
       logIn = LogIn(sessions: sessions),
       restoreSession = RestoreSession(sessions: sessions),
       logOut = LogOut(sessions: sessions),
       sessionExpirations = sessions.expirations;

  /// The same ports over HTTP. In the browser the session lives in a cookie, elsewhere in [tokens].
  factory BackofficeDependencies.server({
    required Uri baseUri,
    required TokenStore tokens,
    Clock clock = const SystemClock(),
  }) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return BackofficeDependencies(
      clock: clock,
      events: HttpEventRepository(api),
      tickets: HttpTicketRepository(api),
      sessions: HttpSessionRepository(api),
    );
  }

  factory BackofficeDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 700),
    bool signedIn = true,
    User staff = organizer,
  }) {
    final fake = FakeBoxOffice(clock: clock, latency: latency);
    return BackofficeDependencies(
      clock: clock,
      events: fake,
      tickets: fake,
      sessions: InMemorySessions(staff, signedIn: signedIn),
      fake: fake,
    );
  }

  final Clock clock;
  final GetOrganizerEvents getOrganizerEvents;
  final GetEventTickets getEventTickets;
  final ConfirmPayment confirmPayment;
  final AdmitTicket admitTicket;
  final VoidTicket voidTicket;
  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;

  /// Only for the debug menu; null with a real implementation.
  final FakeBoxOffice? fake;
}
