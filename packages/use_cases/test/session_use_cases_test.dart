import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

  test('LogIn trims the username and returns the user', () async {
    final sessions = RecordingSessions();
    expect(await LogIn(sessions: sessions)(username: '  ana ', password: 'tajna'), ana);
    expect(sessions.usernames, ['ana']);
  });

  test('an in-memory session refuses an empty password and forgets the user on log out', () async {
    final sessions = InMemorySessions(ana, signedIn: false);

    expect(await LogIn(sessions: sessions)(username: 'ana', password: ''), isNull);
    expect(await RestoreSession(sessions: sessions)(), isNull);
    expect(await LogIn(sessions: sessions)(username: 'ana', password: 'tajna'), ana);
    expect(await RestoreSession(sessions: sessions)(), ana);
    await LogOut(sessions: sessions)();
    expect(await RestoreSession(sessions: sessions)(), isNull);
  });
}

final class RecordingSessions implements SessionRepository {
  final usernames = <String>[];

  @override
  Future<User?> logIn({required String username, required String password}) async {
    usernames.add(username);
    return const User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
  }

  @override
  Future<User?> current() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}
