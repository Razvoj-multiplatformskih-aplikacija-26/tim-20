import 'package:api_client/api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:use_cases/use_cases.dart';

/// The session token in the macOS keychain; the password is never stored.
///
/// The keychain may refuse, for example when the user denies access after a new debug build. Reading then means
/// that there is no saved session, and a failed write or clear fails like any other call of the session port,
/// so the app never waits forever on an error it does not know.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore([
    /// The data protection keychain needs a provisioning profile; the login keychain also works in unsigned builds.
    this._storage = const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false)),
  ]);

  static const _key = 'tim20_session';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> write(String token) => _guard(() => _storage.write(key: _key, value: token));

  @override
  Future<void> clear() => _guard(() => _storage.delete(key: _key));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (cause) {
      throw RepositoryException('Keychain refused', cause: cause);
    }
  }
}
