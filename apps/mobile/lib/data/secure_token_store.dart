import 'package:api_client/api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:use_cases/use_cases.dart';

/// The session token in the platform keychain or keystore; the password is never stored.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'tim20_session';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      final token = await _storage.read(key: _key);
      return token == null || token.isEmpty ? null : token;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> write(String token) => _guard(() => _storage.write(key: _key, value: token));

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      await _guard(() => _storage.write(key: _key, value: ''));
    }
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (cause) {
      throw RepositoryException('Secure storage refused', cause: cause);
    }
  }
}
