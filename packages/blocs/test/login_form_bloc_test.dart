import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

/// A sign-in that never reaches the server.
final class UnreachableSessions implements SessionRepository {
  const UnreachableSessions();

  @override
  Future<User?> logIn({required String username, required String password}) async =>
      throw const RepositoryException('Simulated outage', failure: RepositoryFailure.unreachable);

  @override
  Future<User?> current() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

  blocTest<LoginFormBloc, LoginFormState>(
    'the right password succeeds with the user',
    build: () => LoginFormBloc(logIn: LogIn(sessions: InMemorySessions(ana, signedIn: false))),
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'ana', password: 'tim20-demo')),
    expect: () => [const LoginSubmitting(), const LoginSucceeded(ana)],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a wrong password is rejected',
    build: () => LoginFormBloc(logIn: LogIn(sessions: InMemorySessions(ana, signedIn: false))),
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'ana', password: '')),
    expect: () => [const LoginSubmitting(), const LoginRejected()],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a server that cannot be reached fails with the cause',
    build: () => LoginFormBloc(logIn: const LogIn(sessions: UnreachableSessions())),
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'ana', password: 'tim20-demo')),
    expect: () => [
      const LoginSubmitting(),
      isA<LoginFailed>().having(
        (s) => s.cause,
        'cause',
        isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unreachable),
      ),
    ],
  );
}
