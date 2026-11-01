import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/event_tickets_screen.dart';
import 'screens/events_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const EventsScreen()),
      GoRoute(
        path: '/dogadjaji/:eventId',
        builder: (_, state) {
          final selected = state.uri.queryParameters['selected'];
          return EventTicketsScreen(
            eventId: EventId(state.pathParameters['eventId']!),
            selectedId: selected == null ? null : TicketId(selected),
          );
        },
      ),
    ],
  );
}
