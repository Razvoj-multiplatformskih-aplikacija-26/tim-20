@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

late Pool<void> database;
late RelicServer server;
late Uri base;

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

Future<http.Response> get(String path) => http.get(base.replace(path: path));

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS tim20_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE tim20_test');
    await admin.close();
    database = Pool<void>.withUrl(Uri.parse(config.databaseUrl).replace(path: '/tim20_test').toString());
    await migrateWithDbmate(Uri.parse(config.databaseUrl));
    await seedDemoData(database, now: DateTime.now(), demoPassword: config.demoPassword);
    const clock = SystemClock();
    final handlers = TicketingHandlers(ticketing: PostgresTicketing(database), clock: clock);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(buildHandler(handlers, corsOrigins: const []));
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
}
