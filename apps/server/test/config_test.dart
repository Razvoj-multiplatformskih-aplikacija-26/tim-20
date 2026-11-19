import 'package:server/server.dart';
import 'package:test/test.dart';

void main() {
  test('the configuration comes from the environment, with the browser origins split by commas', () {
    final config = ServerConfig.fromEnvironment({
      'DATABASE_URL': 'postgres://tim20:tim20@db:5432/tim20',
      'HOST': '0.0.0.0',
      'CORS_ORIGINS': 'http://localhost:8081, http://localhost:8083,',
      'DEMO_PASSWORD': 'tim20-demo',
      'JWT_SECRET': 'dev-only-secret-change-me-0123456789abcdef',
      'SESSION_TTL_MINUTES': '1',
    });

    expect(config.host, '0.0.0.0');
    expect(config.port, 8080);
    expect(config.corsOrigins, ['http://localhost:8081', 'http://localhost:8083']);
    expect(config.demoPassword, 'tim20-demo');
    expect(config.sessionTtl, const Duration(minutes: 1));
    expect(config.secureCookie, isFalse);
  });

  test('a missing database address stops the server with a hint', () {
    expect(() => ServerConfig.fromEnvironment(const {}), throwsStateError);
  });

  test('a token secret shorter than 32 bytes is refused', () {
    expect(
      () => ServerConfig.fromEnvironment(const {'DATABASE_URL': 'postgres://db/tim20', 'JWT_SECRET': 'too-short'}),
      throwsStateError,
    );
  });
}
