import 'package:backoffice/data/secure_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'denied', message: 'The user denied access to the keychain.'),
    );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  test('a keychain that refuses to read means no saved session', () async {
    expect(await const SecureTokenStore().read(), isNull);
  });

  test('a keychain that refuses to write or clear fails like the rest of the session port', () async {
    final failsAsRepository = throwsA(isA<RepositoryException>());
    await expectLater(const SecureTokenStore().write('token'), failsAsRepository);
    await expectLater(const SecureTokenStore().clear(), failsAsRepository);
  });
}
