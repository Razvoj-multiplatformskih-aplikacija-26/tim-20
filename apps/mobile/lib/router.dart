import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'screens/event_detail_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_shell.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/ticket_detail_screen.dart';

/// Detail screens take their id from the address, so deep links and restarts work.
GoRouter createRouter({String initialLocation = '/'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/prijava', builder: (context, state) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const EventsScreen(),
                routes: [
                  GoRoute(
                    path: 'dogadjaj/:id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => EventDetailScreen(id: EventId(state.pathParameters['id']!)),
                    routes: [
                      GoRoute(
                        path: 'kupovina',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => _Purchase(id: EventId(state.pathParameters['id']!)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/karte',
                builder: (context, state) => const MyTicketsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => TicketDetailScreen(id: TicketId(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// A purchase belongs to the signed-in visitor, so the form waits for the session instead of a redirect
/// that would lose a deep link opened before the session is restored.
class _Purchase extends StatelessWidget {
  const _Purchase({required this.id});

  final EventId id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, session) => switch (session) {
        SessionUnknown() => Scaffold(
          appBar: AppBar(title: const Text('Kupovina')),
          body: const LoadingView(),
        ),
        SignedOut() => Scaffold(
          appBar: AppBar(title: const Text('Kupovina')),
          body: ListView(
            children: [
              const EmptyView(title: 'Prijavite se da kupite karte.'),
              Center(
                child: FilledButton(onPressed: () => ensureSignedIn(context), child: const Text('Prijavi se')),
              ),
            ],
          ),
        ),
        SignedIn(:final user) => BlocProvider(
          key: ValueKey(user.id),
          create: (context) {
            final dependencies = context.read<AppDependencies>();
            return PurchaseBloc(
              getPurchaseContext: dependencies.getPurchaseContext,
              reserveTickets: dependencies.reserveTickets,
              visitor: user,
            )..add(PurchaseStarted(id));
          },
          child: PurchaseScreen(id: id),
        ),
      },
    );
  }
}
