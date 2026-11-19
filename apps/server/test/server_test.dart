@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

late Pool<void> database;
late RelicServer server;
late Uri base;
late String demoPassword;
late String jwtSecret;

const browser = 'http://localhost:8081';

Future<void> migrateWithDbmate(Uri databaseUrl) async {
  final insideCompose = databaseUrl.replace(host: 'db', port: 5432, path: '/tim20_test');
  final result = await Process.run('docker', [
    'compose',
    'run',
    '--rm',
    '-e',
    'DATABASE_URL=$insideCompose',
    'migrate',
  ], workingDirectory: '../..');
  if (result.exitCode != 0) throw StateError('dbmate failed: ${result.stderr}');
}

Future<http.Response> get(String path, {String? token}) =>
    http.get(base.replace(path: path), headers: {'Authorization': ?bearer(token)});

String? bearer(String? token) => token == null ? null : 'Bearer $token';

Map<String, String> as(String token) => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

Future<http.Response> signIn(String login, {String? password, bool cookie = false}) => http.post(
  base.replace(path: ApiPaths.sessions),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(LoginDto(username: login, password: password ?? demoPassword, cookie: cookie).toJson()),
);

Future<String> logIn(String login) async =>
    SessionDto.fromJson(jsonDecode((await signIn(login)).body) as Map<String, Object?>).token!;

Future<http.Response> reserve(String token, String eventId, int quantity) => http.post(
  base.replace(path: ApiPaths.reservations(eventId)),
  headers: as(token),
  body: jsonEncode(NewReservationDto(quantity: quantity).toJson()),
);

Future<http.Response> act(String token, String path, {Object? body}) => http.post(
  base.replace(path: path),
  headers: as(token),
  body: body == null ? null : jsonEncode(body),
);

Map<String, Object?> problemOf(http.Response response) => jsonDecode(response.body) as Map<String, Object?>;

Future<int> activeTickets(String eventId) async {
  final rows = await database.execute(
    Sql.named('''
      SELECT count(*) FROM tickets
      WHERE event_id = @event AND (status IN ('paid', 'used') OR (status = 'reserved' AND expires_at > now()))
    '''),
    parameters: {'event': eventId},
  );
  return rows.single[0]! as int;
}

String tokenFor(String userId, String role, {required String secret, Duration expiresIn = const Duration(hours: 1)}) =>
    JWT({'name': userId, 'role': role}, subject: userId).sign(SecretKey(secret), expiresIn: expiresIn);

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    demoPassword = config.demoPassword!;
    jwtSecret = config.jwtSecret;
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS tim20_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE tim20_test');
    await admin.close();
    database = Pool<void>.withUrl(Uri.parse(config.databaseUrl).replace(path: '/tim20_test').toString());
    await migrateWithDbmate(Uri.parse(config.databaseUrl));
    await seedDemoData(database, now: DateTime.now(), demoPassword: config.demoPassword);
    const clock = SystemClock();
    final handlers = TicketingHandlers(
      ticketing: PostgresTicketing(database),
      clock: clock,
      payments: FakePaymentGateway(apiKey: config.paymentApiKey),
    );
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    final sessions = SessionHandlers(
      accounts: AccountStore(database),
      secret: jwtSecret,
      ttl: const Duration(hours: 1),
    );
    await server.mountAndStart(buildHandler(handlers, sessions, corsOrigins: const [browser]));
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  test('events are public and sorted by start', () async {
    final answer = await get(ApiPaths.events);

    expect(answer.statusCode, 200);
    final events = [
      for (final item in jsonDecode(answer.body) as List<Object?>) EventDto.fromJson(item! as Map<String, Object?>),
    ];
    expect(events.length, greaterThanOrEqualTo(5));
    final starts = [for (final event in events) event.startsAt];
    expect(starts, [...starts]..sort());
    expect(events.first.price.currency, MoneyDto.rsd);
  });

  test('an unknown event is 404 not-found as a problem', () async {
    final answer = await get(ApiPaths.event('e-missing'));

    expect(answer.statusCode, 404);
    expect(answer.headers['content-type'], startsWith(ProblemDto.mediaType));
    expect(codeOf(answer), ErrorCodes.notFound);
  });

  test('the last-seat event has exactly one seat left', () async {
    final answer = await get(ApiPaths.seats('e-3'));

    expect(answer.statusCode, 200);
    expect(SeatsDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>).remaining, 1);
  });

  test('the seed has ten tickets or more and every status at least twice', () async {
    final rows = await database.execute('''
      SELECT CASE WHEN status = 'reserved' AND expires_at < now() THEN 'expired' ELSE status END, count(*)
      FROM tickets
      GROUP BY 1
    ''');
    final counts = {for (final row in rows) row[0]! as String: row[1]! as int};

    expect(counts.values.fold(0, (sum, count) => sum + count), greaterThanOrEqualTo(10));
    for (final status in ['reserved', 'paid', 'used', 'cancelled', 'expired']) {
      expect(counts[status], greaterThanOrEqualTo(2), reason: status);
    }
  });

  test('the seed has an account for every role and two for the mobile app', () async {
    final rows = await database.execute('SELECT role, count(*) FROM users WHERE login IS NOT NULL GROUP BY role');
    final accounts = {for (final row in rows) row[0]! as String: row[1]! as int};

    expect(accounts, {'visitor': 2, 'organizer': 1, 'usher': 1});
  });

  test('an unknown route is 404 and a wrong method is 405', () async {
    expect((await get('/api/v1/nothing')).statusCode, 404);
    expect((await http.post(base.replace(path: ApiPaths.events))).statusCode, 405);
  });

  test('ana signs in and the session names her', () async {
    final answer = await signIn('ana');

    expect(answer.statusCode, 201);
    final session = SessionDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>);
    expect(session.user.role, UserDto.visitor);
    final current = await get(ApiPaths.currentSession, token: session.token);
    expect(current.statusCode, 200);
    expect(SessionDto.fromJson(jsonDecode(current.body) as Map<String, Object?>).user.id, 'u-ana');
  });

  test('a wrong password and an unknown login are both 401 invalid-credentials', () async {
    final answers = [await signIn('ana', password: 'pogresna'), await signIn('niko')];

    expect(answers.map((answer) => answer.statusCode), [401, 401]);
    expect(answers.map(codeOf), everyElement(ErrorCodes.invalidCredentials));
  });

  test('without a token the server asks to sign in', () async {
    final answer = await get(ApiPaths.currentSession);

    expect(answer.statusCode, 401);
    expect(codeOf(answer), ErrorCodes.signInRequired);
  });

  test('a forged, foreign or expired token is 401 session-expired', () async {
    final tokens = [
      'lazni.token.ovde',
      tokenFor('u-ana', 'visitor', secret: 'another-secret-that-is-long-enough-0123456789'),
      tokenFor('u-ana', 'visitor', secret: jwtSecret, expiresIn: const Duration(minutes: -1)),
      JWT(
        const {'name': 'Ana', 'role': 'visitor'},
        subject: 'u-ana',
      ).sign(SecretKey(jwtSecret), algorithm: JWTAlgorithm.HS512, expiresIn: const Duration(hours: 1)),
    ];

    final answers = [for (final token in tokens) await get(ApiPaths.currentSession, token: token)];

    expect(answers.map((answer) => answer.statusCode), everyElement(401));
    expect(answers.map(codeOf), everyElement(ErrorCodes.sessionExpired));
    expect(answers.first.headers['www-authenticate'], 'Bearer');
  });

  test('a browser sign-in keeps the session in an HttpOnly cookie and signing out clears it', () async {
    final answer = await signIn('organizator', cookie: true);

    expect(answer.statusCode, 201);
    expect(SessionDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>).token, isNull);
    final cookie = answer.headers['set-cookie']!;
    expect(cookie, allOf(startsWith('${ApiCookies.session}='), contains('HttpOnly'), contains('SameSite=Lax')));

    final session = cookie.split(';').first;
    final current = await http.get(base.replace(path: ApiPaths.currentSession), headers: {'Cookie': session});
    expect(current.statusCode, 200);
    final out = await http.delete(base.replace(path: ApiPaths.currentSession), headers: {'Cookie': session});
    expect(out.statusCode, 204);
    expect(out.headers['set-cookie'], contains('Max-Age=0'));
  });

  test('passwords are stored only as Argon2id hashes', () async {
    final rows = await database.execute('SELECT password_hash FROM users WHERE login IS NOT NULL');

    expect(rows, hasLength(4));
    for (final row in rows) {
      expect(row[0], startsWith(r'$argon2id$'));
    }
  });

  test('the browser origin from CORS_ORIGINS passes the preflight and another origin may not write', () async {
    final request = http.Request('OPTIONS', base.replace(path: ApiPaths.sessions))
      ..headers['Origin'] = browser
      ..headers['Access-Control-Request-Method'] = 'POST';
    final preflight = await http.Response.fromStream(await request.send());
    final foreign = await http.post(base.replace(path: ApiPaths.sessions), headers: {'Origin': 'http://evil.example'});

    expect(preflight.statusCode, 204);
    expect(preflight.headers['access-control-allow-origin'], browser);
    expect(preflight.headers['access-control-allow-credentials'], 'true');
    expect(foreign.statusCode, 403);
  });
}
