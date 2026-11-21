import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

const _title = 'Ulaznice · backoffice';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies});

  final BackofficeDependencies dependencies;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  late final SessionBloc _session = SessionBloc(
    restoreSession: widget.dependencies.restoreSession,
    logOut: widget.dependencies.logOut,
    admits: AccessPolicy.canUseBackoffice,
    expirations: widget.dependencies.sessionExpirations,
  )..add(const SessionRestoreRequested());

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider.value(
        value: _session,
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, session) => switch (session) {
            SessionUnknown() => _material(
              key: const ValueKey('session-unknown'),
              home: const Scaffold(body: LoadingView()),
            ),
            SignedOut(:final reason) => _material(
              key: ValueKey('signed-out ${reason?.name}'),
              home: LoginScreen(
                title: _title,
                logIn: dependencies.logIn,
                reason: reason,
                roleNotAllowedMessage: 'Backoffice je za organizatore i redare.',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            SignedIn(:final user) => _SignedInApp(key: ValueKey(user.id), staff: user, dependencies: dependencies),
          },
        ),
      ),
    );
  }
}

/// A new router and a new list of events for every signed-in user, so nothing of the previous one stays on screen.
class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.staff, required this.dependencies});

  final User staff;
  final BackofficeDependencies dependencies;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.staff,
      child: BlocProvider(
        create: (_) =>
            OrganizerEventsBloc(widget.dependencies.getOrganizerEvents, organizer: widget.staff)
              ..add(const OrganizerEventsRequested()),
        child: _material(router: _router),
      ),
    );
  }
}

/// Before sign-in the address of the page is kept for the router, so the app does not try to open it as a route.
Widget _material({Key? key, Widget? home, GoRouter? router}) {
  if (router != null) {
    return MaterialApp.router(
      key: key,
      title: _title,
      debugShowCheckedModeBanner: false,
      theme: TicketsTheme.light(),
      darkTheme: TicketsTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: _title,
    debugShowCheckedModeBanner: false,
    theme: TicketsTheme.light(),
    darkTheme: TicketsTheme.dark(),
    themeMode: ThemeMode.system,
    onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(builder: (_) => home!)],
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => home!),
  );
}
