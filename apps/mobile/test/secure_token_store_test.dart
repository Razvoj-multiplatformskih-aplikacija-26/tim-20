import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/secure_token_store.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  test('a storage that refuses to read means no saved session', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'denied'),
    );

    expect(await const SecureTokenStore().read(), isNull);
  });

  test('write and clear failures become repository exceptions', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'denied'),
    );
    const store = SecureTokenStore();

    await expectLater(store.write('token'), throwsA(isA<RepositoryException>()));
    await expectLater(store.clear(), throwsA(isA<RepositoryException>()));
  });

  test('a failed delete writes an empty tombstone', () async {
    var stored = 'expired-token';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      switch (call.method) {
        case 'delete':
          throw PlatformException(code: 'denied');
        case 'write':
          stored = arguments['value']! as String;
          return null;
        case 'read':
          return stored;
        default:
          return null;
      }
    });
    const store = SecureTokenStore();

    await store.clear();

    expect(stored, '');
    expect(await store.read(), isNull);
  });
}
