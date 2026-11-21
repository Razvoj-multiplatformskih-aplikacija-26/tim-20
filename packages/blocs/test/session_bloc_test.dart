import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

/// A session the server remembers, which a test can end or break.
final class RememberedSession implements SessionRepository {
  RememberedSession(this.remembered, {this.failure, this.restoreError});

  User? remembered;
  RepositoryFailure? failure;
  Object? restoreError;
  int logOuts = 0;
  final _expirations = StreamController<void>.broadcast();

  void expire() => _expirations.add(null);

  @override
  Future<User?> logIn({required String username, required String password}) async => null;

  @override
  Future<User?> current() async {
    if (restoreError case final error?) throw error;
    if (failure case final failure?) throw RepositoryException('Simulated', failure: failure);
    return remembered;
  }

  @override
  Future<void> logOut() async {
    logOuts++;
    remembered = null;
  }

  @override
  Stream<void> get expirations => _expirations.stream;
}

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
  const organizer = User(id: UserId('u-org'), name: 'Jovana Organizator', role: Role.organizer);
  late RememberedSession sessions;

  SessionBloc build() => SessionBloc(
    restoreSession: RestoreSession(sessions: sessions),
    logOut: LogOut(sessions: sessions),
    admits: AccessPolicy.canUseMobileApp,
    expirations: sessions.expirations,
  );

  blocTest<SessionBloc, SessionState>(
    'restore with no session signs out without a reason',
    setUp: () => sessions = RememberedSession(null),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut()],
  );

  blocTest<SessionBloc, SessionState>(
    'restore of an admitted user signs in',
    setUp: () => sessions = RememberedSession(ana),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedIn(ana)],
  );

  blocTest<SessionBloc, SessionState>(
    'restore of a user the app does not admit logs out quietly and says why',
    setUp: () => sessions = RememberedSession(organizer),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
    verify: (_) => expect(sessions.logOuts, 1),
  );

  blocTest<SessionBloc, SessionState>(
    'restore when the server is down signs out as unreachable',
    setUp: () => sessions = RememberedSession(ana, failure: RepositoryFailure.unreachable),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [
      isA<SignedOut>()
          .having((state) => state.reason, 'reason', SignOutReason.unreachable)
          .having(
            (state) => (state.cause as RepositoryException).failure,
            'cause failure',
            RepositoryFailure.unreachable,
          ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'restore with an expired token signs out as expired',
    setUp: () => sessions = RememberedSession(ana, failure: RepositoryFailure.sessionExpired),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [
      isA<SignedOut>()
          .having((state) => state.reason, 'reason', SignOutReason.expired)
          .having(
            (state) => (state.cause as RepositoryException).failure,
            'cause failure',
            RepositoryFailure.sessionExpired,
          ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'a server error while restoring is not reported as unreachable',
    setUp: () => sessions = RememberedSession(ana, failure: RepositoryFailure.serverError),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [
      isA<SignedOut>()
          .having((state) => state.reason, 'reason', SignOutReason.restoreFailed)
          .having((state) => state.cause, 'cause', isA<RepositoryException>()),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'a non-repository error while restoring is retained as the cause',
    setUp: () => sessions = RememberedSession(ana, restoreError: StateError('unexpected')),
    build: build,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [
      isA<SignedOut>()
          .having((state) => state.reason, 'reason', SignOutReason.restoreFailed)
          .having((state) => state.cause, 'cause', isA<StateError>()),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'retrying restoration shows SessionUnknown while it is in progress',
    setUp: () => sessions = RememberedSession(ana, failure: RepositoryFailure.serverError),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedOut);
      sessions.failure = null;
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedIn);
    },
    expect: () => [
      isA<SignedOut>().having((state) => state.reason, 'reason', SignOutReason.restoreFailed),
      const SessionUnknown(),
      const SignedIn(ana),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'skipping restoration returns to ordinary sign-out',
    setUp: () => sessions = RememberedSession(ana, failure: RepositoryFailure.serverError),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedOut);
      bloc.add(const SessionRestoreSkipped());
    },
    expect: () => [
      isA<SignedOut>().having((state) => state.reason, 'reason', SignOutReason.restoreFailed),
      const SignedOut(),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'an expiration while signed in ends the session with a reason',
    setUp: () => sessions = RememberedSession(ana),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedIn);
      sessions.expire();
    },
    expect: () => [const SignedIn(ana), const SignedOut(reason: SignOutReason.expired)],
  );

  blocTest<SessionBloc, SessionState>(
    'an expiration while signed out changes nothing',
    setUp: () => sessions = RememberedSession(null),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedOut);
      sessions.expire();
    },
    expect: () => [const SignedOut()],
  );

  blocTest<SessionBloc, SessionState>(
    'a sign-in from the form starts the session',
    setUp: () => sessions = RememberedSession(null),
    build: build,
    act: (bloc) => bloc.add(const SessionStarted(ana)),
    expect: () => [const SignedIn(ana)],
  );

  blocTest<SessionBloc, SessionState>(
    'log out ends the session and says so',
    setUp: () => sessions = RememberedSession(ana),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await bloc.stream.firstWhere((state) => state is SignedIn);
      bloc.add(const SessionLogOutRequested());
    },
    expect: () => [const SignedIn(ana), const SignedOut(reason: SignOutReason.loggedOut)],
    verify: (_) => expect(sessions.logOuts, 1),
  );
}
