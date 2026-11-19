import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key, required this.dependencies, this.initialLocation = '/'});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;
  final String initialLocation;

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SessionBloc(
              restoreSession: dependencies.restoreSession,
              logOut: dependencies.logOut,
              admits: AccessPolicy.canUseMobileApp,
              expirations: dependencies.sessionExpirations,
            )..add(const SessionRestoreRequested()),
          ),
          BlocProvider(create: (_) => EventsBloc(dependencies.getUpcomingEvents)..add(const EventsRequested())),
          BlocProvider(
            create: (_) => MyTicketsBloc(
              getMyTickets: dependencies.getMyTickets,
              payTicket: dependencies.payTicket,
              cancelTicket: dependencies.cancelTicket,
              clock: dependencies.clock,
            ),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<SessionBloc, SessionState>(
              listenWhen: (previous, current) => current is! SessionUnknown,
              listener: (context, session) => context.read<MyTicketsBloc>().add(
                MyTicketsVisitorChanged(switch (session) {
                  SignedIn(:final user) => user,
                  SessionUnknown() || SignedOut() => null,
                }),
              ),
            ),
            BlocListener<SessionBloc, SessionState>(
              listenWhen: (previous, current) =>
                  previous is SignedIn && current is SignedOut && current.reason == SignOutReason.expired,
              listener: (context, session) => _router.push('/prijava'),
            ),
          ],
          child: MaterialApp.router(
            title: 'Ulaznice',
            theme: TicketsTheme.light(),
            darkTheme: TicketsTheme.dark(),
            themeMode: ThemeMode.system,
            locale: MobileApp.locale,
            supportedLocales: const [MobileApp.locale],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
