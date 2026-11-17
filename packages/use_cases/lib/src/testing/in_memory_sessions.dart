import 'package:domain/domain.dart';

import '../ports/session_repository.dart';

/// A session without a server: any non-empty password signs [user] in.
final class InMemorySessions implements SessionRepository {
  InMemorySessions(this._user, {bool signedIn = true}) : _current = signedIn ? _user : null;

  final User _user;
  User? _current;

  @override
  Future<User?> logIn({required String username, required String password}) async =>
      _current = password.isEmpty ? null : _user;

  @override
  Future<User?> current() async => _current;

  @override
  Future<void> logOut() async => _current = null;

  @override
  Stream<void> get expirations => const Stream.empty();
}
