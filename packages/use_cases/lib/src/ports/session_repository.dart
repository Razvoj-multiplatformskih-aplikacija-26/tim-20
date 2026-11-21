import 'package:domain/domain.dart';

abstract interface class SessionRepository {
  /// Null when the username or the password is wrong.
  Future<User?> logIn({required String username, required String password});

  Future<User?> current();

  Future<void> logOut();

  /// Fires when the server no longer accepts the session.
  Stream<void> get expirations;
}
