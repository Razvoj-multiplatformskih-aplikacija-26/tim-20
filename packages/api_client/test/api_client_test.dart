import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
const organizer = User(id: UserId('u-org'), name: 'Jovana Organizator', role: Role.organizer);
final now = DateTime.utc(2026, 11, 20, 12);

final concert = Event(
  id: const EventId('e-3'),
  name: 'Koncert',
  venue: 'Dom omladine',
  startsAt: now.add(const Duration(days: 10)),
  priceRsd: 1200,
  capacity: 5,
  organizerId: organizer.id,
);

Ticket ticket(String id, {required TicketStatus status}) => Ticket(
  id: TicketId(id),
  eventId: concert.id,
  holderId: ana.id,
  holderName: ana.name,
  status: status,
  createdAt: now.subtract(const Duration(hours: 1)),
  code: 'T20-$id',
);

http.Response json(Object? body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response problem(ProblemDto problem) =>
    http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});

ApiClient apiOver(
  MockClient server, {
  TokenStore? tokens,
  bool keepsSessionInCookie = false,
  Duration timeout = const Duration(seconds: 10),
}) => ApiClient(
  baseUri: Uri.parse('http://localhost:8080'),
  tokens: tokens,
  httpClient: server,
  keepsSessionInCookie: keepsSessionInCookie,
  timeout: timeout,
);

Future<TokenStore> tokenOfAna() async {
  final tokens = MemoryTokenStore();
  await tokens.write('token-of-ana');
  return tokens;
}

final class _CannotClearTokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'expired-token';

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async => throw const RepositoryException('Cannot clear token');
}

void main() {
  group('tickets', () {
    test('the server taking the last seat first reaches the client as NotEnoughSeats', () async {
      final server = MockClient(
        (request) async => problem(
          const ProblemDto(status: 409, code: ErrorCodes.notEnoughSeats, title: 'Not enough seats', value: 0),
        ),
      );

      final result = await HttpTicketRepository(apiOver(server))
          .reserve(eventId: concert.id, by: ana, quantity: 1, now: now);

      expect(result, const Failure<List<Ticket>>(NotEnoughSeats(0)));
    });

    test('a reservation posts the quantity with the bearer token', () async {
      late http.Request seen;
      final server = MockClient((request) async {
        seen = request;
        return json([ticket('t-9', status: Reserved(expiresAt: now)).toDto().toJson()], status: 201);
      });

      final result = await HttpTicketRepository(apiOver(server, tokens: await tokenOfAna()))
          .reserve(eventId: concert.id, by: ana, quantity: 2, now: now);

      expect(seen.method, 'POST');
      expect(seen.url.path, ApiPaths.reservations('e-3'));
      expect(jsonDecode(seen.body), {'quantity': 2});
      expect(seen.headers['Authorization'], 'Bearer token-of-ana');
      expect(
        result,
        isA<Success<List<Ticket>>>().having((r) => r.value, 'value', [ticket('t-9', status: Reserved(expiresAt: now))]),
      );
    });

    test('admitting posts to admission and confirming to payment-confirmation', () async {
      final paths = <String>[];
      final server = MockClient((request) async {
        paths.add(request.url.path);
        return json(ticket('t-2', status: Paid(paidAt: now)).toDto().toJson());
      });
      final tickets = HttpTicketRepository(apiOver(server));
      final reserved = Reserved(expiresAt: now);

      await tickets.save(
        ticket(
          't-2',
          status: Used(scannedAt: now, scannedBy: organizer.id),
        ),
        from: reserved,
      );
      await tickets.save(
        ticket(
          't-2',
          status: Paid(paidAt: now, confirmedBy: organizer.id),
        ),
        from: reserved,
      );
      await tickets.save(
        ticket('t-2', status: Paid(paidAt: now)),
        from: reserved,
      );
      await tickets.save(
        ticket(
          't-2',
          status: Cancelled(at: now, by: ana.id, reason: 'x'),
        ),
        from: reserved,
      );

      expect(paths, [
        ApiPaths.admission('t-2'),
        ApiPaths.paymentConfirmation('t-2'),
        ApiPaths.payment('t-2'),
        ApiPaths.cancellation('t-2'),
      ]);
    });

    test('a reservation is created, not saved', () {
      final tickets = HttpTicketRepository(apiOver(MockClient((request) async => json(null))));

      expect(
        () => tickets.save(
          ticket('t-1', status: Reserved(expiresAt: now)),
          from: Reserved(expiresAt: now),
        ),
        throwsArgumentError,
      );
    });

    test('an unreachable server and a server that does not answer in time become unreachable', () async {
      final refusing = MockClient((request) async => throw http.ClientException('Connection refused', request.url));
      final silent = MockClient((request) => Future.delayed(const Duration(seconds: 1), () => json([])));

      final unreachable = isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unreachable);
      await expectLater(HttpTicketRepository(apiOver(refusing)).ticketsOf(ana.id), throwsA(unreachable));
      await expectLater(
        HttpTicketRepository(apiOver(silent, timeout: const Duration(milliseconds: 50))).ticketsOf(ana.id),
        throwsA(unreachable),
      );
    });

    test('a 500 becomes serverError', () {
      final server = MockClient((request) async => http.Response('boom', 500));

      expect(
        HttpTicketRepository(apiOver(server)).ticketsOf(ana.id),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.serverError)),
      );
    });

    test('an unknown error code from a newer server becomes refused', () {
      final server = MockClient(
        (request) async => problem(const ProblemDto(status: 409, code: 'seat-on-fire', title: 'Seat on fire')),
      );

      expect(
        HttpTicketRepository(apiOver(server)).reserve(eventId: concert.id, by: ana, quantity: 1, now: now),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.refused)),
      );
    });

    test('an unknown status kind becomes serverError, not a crash', () {
      final server = MockClient((request) async {
        final dto = ticket('t-1', status: Paid(paidAt: now)).toDto().toJson();
        dto['status'] = {'kind': 'refunded', 'at': instantToJson(now)};
        return json([dto]);
      });

      expect(
        HttpTicketRepository(apiOver(server)).ticketsOf(ana.id),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.serverError)),
      );
    });

    test('a limit from the server reaches the client with its max', () async {
      final server = MockClient(
        (request) async => problem(
          const ProblemDto(
            status: 409,
            code: ErrorCodes.ticketLimitExceeded,
            title: 'Ticket limit exceeded',
            held: 1,
            value: 2,
            max: 2,
          ),
        ),
      );

      final result = await HttpTicketRepository(apiOver(server))
          .reserve(eventId: concert.id, by: ana, quantity: 2, now: now);

      expect(result, const Failure<List<Ticket>>(TicketLimitExceeded(alreadyHeld: 1, requested: 2, max: 2)));
    });

    test('a missing ticket is null', () async {
      final server = MockClient(
        (request) async => problem(const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found')),
      );

      expect(await HttpTicketRepository(apiOver(server)).findTicket(const TicketId('t-404')), isNull);
    });
  });

  group('events', () {
    test('seats come from the seats endpoint, not from the tickets of others', () async {
      final paths = <String>[];
      final server = MockClient((request) async {
        paths.add(request.url.path);
        return json(const SeatsDto(remaining: 1).toJson());
      });

      final remaining = await HttpEventRepository(apiOver(server)).remainingSeats(concert.id, now: now);

      expect(remaining, 1);
      expect(paths, [ApiPaths.seats('e-3')]);
    });

    test('events arrive as the domain reads them', () async {
      final server = MockClient((request) async => json([concert.toDto().toJson()]));

      expect(await HttpEventRepository(apiOver(server)).upcoming(), [concert]);
    });
  });

  group('sessions', () {
    SessionDto sessionOf(User user, {String? token}) =>
        SessionDto(user: user.toDto(), expiresAt: now.add(const Duration(hours: 8)), token: token);

    test('401 session-expired announces the expiration and throws sessionExpired', () async {
      final server = MockClient(
        (request) async =>
            problem(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Session expired')),
      );
      final api = apiOver(server, tokens: await tokenOfAna());
      final announced = api.expirations.first;

      await expectLater(
        HttpTicketRepository(api).ticketsOf(ana.id),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.sessionExpired)),
      );
      await expectLater(announced.timeout(const Duration(seconds: 1)), completes);
    });

    test('restoring with a stored but expired token clears it and throws sessionExpired', () async {
      final tokens = await tokenOfAna();
      final server = MockClient(
        (request) async =>
            problem(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Session expired')),
      );

      await expectLater(
        HttpSessionRepository(apiOver(server, tokens: tokens)).current(),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.sessionExpired)),
      );
      expect(await tokens.read(), isNull);
    });

    test('a failed token clear does not hide an expired session', () async {
      final server = MockClient(
        (request) async =>
            problem(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Session expired')),
      );

      await expectLater(
        HttpSessionRepository(apiOver(server, tokens: _CannotClearTokenStore())).current(),
        throwsA(
          isA<RepositoryException>().having((error) => error.failure, 'failure', RepositoryFailure.sessionExpired),
        ),
      );
    });

    test('restoring without a stored token asks nothing and is null', () async {
      var calls = 0;
      final server = MockClient((request) async {
        calls++;
        return json(sessionOf(ana).toJson());
      });

      expect(await HttpSessionRepository(apiOver(server)).current(), isNull);
      expect(calls, 0);
    });

    test('a wrong password signs in as null', () async {
      final server = MockClient(
        (request) async =>
            problem(const ProblemDto(status: 401, code: ErrorCodes.invalidCredentials, title: 'Invalid credentials')),
      );

      expect(await HttpSessionRepository(apiOver(server)).logIn(username: 'ana', password: 'nope'), isNull);
    });

    test('a sign-in stores the token', () async {
      final tokens = MemoryTokenStore();
      final server = MockClient((request) async {
        expect(request.url.path, ApiPaths.sessions);
        expect(jsonDecode(request.body), {'username': 'ana', 'password': 'tim20-demo', 'cookie': false});
        return json(sessionOf(ana, token: 'fresh-token').toJson(), status: 201);
      });

      final user = await HttpSessionRepository(apiOver(server, tokens: tokens))
          .logIn(username: 'ana', password: 'tim20-demo');

      expect(user, ana);
      expect(await tokens.read(), 'fresh-token');
    });

    test('in the browser mode no Authorization header is sent and the cookie is asked for', () async {
      final tokens = await tokenOfAna();
      late http.Request seen;
      final server = MockClient((request) async {
        seen = request;
        return json(sessionOf(ana).toJson(), status: 201);
      });

      await HttpSessionRepository(apiOver(server, tokens: tokens, keepsSessionInCookie: true))
          .logIn(username: 'ana', password: 'tim20-demo');

      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(seen.body), containsPair('cookie', true));
    });

    test('logging out clears the token even when the server is down', () async {
      final tokens = await tokenOfAna();
      final server = MockClient((request) async => throw http.ClientException('Connection refused', request.url));

      await expectLater(HttpSessionRepository(apiOver(server, tokens: tokens)).logOut(), throwsA(anything));
      expect(await tokens.read(), isNull);
    });
  });
}
