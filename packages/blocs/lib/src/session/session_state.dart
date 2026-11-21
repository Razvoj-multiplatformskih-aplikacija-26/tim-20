part of 'session_bloc.dart';

enum SignOutReason { loggedOut, expired, unreachable, restoreFailed, roleNotAllowed }

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SignedOut extends SessionState {
  const SignedOut({this.reason, this.cause});

  final SignOutReason? reason;
  final Object? cause;

  @override
  List<Object?> get props => [reason, cause];

  @override
  String toString() => 'SignedOut(${reason?.name})';
}

final class SignedIn extends SessionState {
  const SignedIn(this.user);

  final User user;

  @override
  List<Object?> get props => [user];

  @override
  String toString() => 'SignedIn($user)';
}
