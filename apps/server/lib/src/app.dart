import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'handlers.dart';
import 'http.dart';
import 'sessions.dart';

Handler buildHandler(TicketingHandlers handlers, SessionHandlers sessions, {required List<String> corsOrigins}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..get(ApiPaths.events, handlers.events)
    ..get(ApiPaths.event(':id'), handlers.event)
    ..get(ApiPaths.seats(':id'), handlers.seats)
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
    ..get(ApiPaths.eventTickets(':id'), signedIn(handlers.eventTickets))
    ..post(ApiPaths.reservations(':id'), signedIn(handlers.reserve))
    ..get(ApiPaths.ticketsOfUser(':userId'), signedIn(handlers.ticketsOfUser))
    ..get(ApiPaths.ticket(':id'), signedIn(handlers.ticket))
    ..post(ApiPaths.payment(':id'), signedIn(handlers.payment))
    ..post(ApiPaths.paymentConfirmation(':id'), signedIn(handlers.paymentConfirmation))
    ..post(ApiPaths.admission(':id'), signedIn(handlers.admission))
    ..post(ApiPaths.cancellation(':id'), signedIn(handlers.cancellation))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
