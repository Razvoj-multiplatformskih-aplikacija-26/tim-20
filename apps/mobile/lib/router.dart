import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/event_detail_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_shell.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/ticket_detail_screen.dart';

/// Detail screens take their id from the address, so deep links and restarts work.
GoRouter createRouter({String initialLocation = '/'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
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
                        builder: (context, state) {
                          final id = EventId(state.pathParameters['id']!);
                          final dependencies = context.read<AppDependencies>();
                          return BlocProvider(
                            create: (_) => PurchaseBloc(
                              getPurchaseContext: dependencies.getPurchaseContext,
                              reserveTickets: dependencies.reserveTickets,
                              visitor: dependencies.visitor,
                            )..add(PurchaseStarted(id)),
                            child: PurchaseScreen(id: id),
                          );
                        },
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
