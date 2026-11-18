import 'package:server/server.dart';
import 'package:test/test.dart';

void main() {
  test('the configuration comes from the environment, with the browser origins split by commas', () {
    final config = ServerConfig.fromEnvironment({
      'DATABASE_URL': 'postgres://tim20:tim20@db:5432/tim20',
      'HOST': '0.0.0.0',
      'CORS_ORIGINS': 'http://localhost:8081, http://localhost:8083,',
      'DEMO_PASSWORD': 'tim20-demo',
    });

    expect(config.host, '0.0.0.0');
    expect(config.port, 8080);
    expect(config.corsOrigins, ['http://localhost:8081', 'http://localhost:8083']);
    expect(config.demoPassword, 'tim20-demo');
  });

  test('a missing database address stops the server with a hint', () {
    expect(() => ServerConfig.fromEnvironment(const {}), throwsStateError);
  });
}
