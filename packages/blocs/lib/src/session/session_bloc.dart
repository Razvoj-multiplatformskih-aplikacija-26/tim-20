import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Who is signed in, shared by every screen; [admits] decides which role this app is for.
final class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required this.restoreSession,
    required this.logOut,
    required this.admits,
    required Stream<void> expirations,
  }) : super(const SessionUnknown()) {
    on<SessionRestoreRequested>(_onRestoreRequested);
    on<SessionRestoreSkipped>((event, emit) => emit(const SignedOut()));
    on<SessionStarted>(_onStarted);
    on<SessionLogOutRequested>(_onLogOutRequested);
    on<SessionExpired>((event, emit) {
      if (state is SignedIn) emit(const SignedOut(reason: SignOutReason.expired));
    });
    _expirations = expirations.listen((_) => add(const SessionExpired()));
  }

  final RestoreSession restoreSession;
  final LogOut logOut;
  final bool Function(User user) admits;
  late final StreamSubscription<void> _expirations;
  bool _restoring = false;

  Future<void> _onRestoreRequested(SessionRestoreRequested event, Emitter<SessionState> emit) async {
    if (_restoring) return;
    _restoring = true;
    if (state is! SessionUnknown) emit(const SessionUnknown());
    try {
      final user = await restoreSession();
      if (user == null) return emit(const SignedOut());
      add(SessionStarted(user));
    } on RepositoryException catch (cause) {
      final reason = switch (cause.failure) {
        RepositoryFailure.unreachable => SignOutReason.unreachable,
        RepositoryFailure.sessionExpired => SignOutReason.expired,
        _ => SignOutReason.restoreFailed,
      };
      emit(SignedOut(reason: reason, cause: cause));
    } on Object catch (cause) {
      emit(SignedOut(reason: SignOutReason.restoreFailed, cause: cause));
    } finally {
      _restoring = false;
    }
  }

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    if (admits(event.user)) {
      emit(SignedIn(event.user));
      return;
    }
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.roleNotAllowed));
  }

  Future<void> _onLogOutRequested(SessionLogOutRequested event, Emitter<SessionState> emit) async {
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.loggedOut));
  }

  Future<void> _logOutQuietly() async {
    try {
      await logOut();
    } on RepositoryException catch (cause, stackTrace) {
      addError(cause, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _expirations.cancel();
    return super.close();
  }
}
