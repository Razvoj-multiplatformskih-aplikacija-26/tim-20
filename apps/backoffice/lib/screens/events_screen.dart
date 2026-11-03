import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static String pathFor(EventId id) => '/dogadjaji/${id.value}';

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrganizerEventsBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulaznice · organizator'),
        actions: [
          IconButton(
            tooltip: 'Osveži',
            icon: const Icon(Icons.refresh),
            onPressed: () => bloc.add(const OrganizerEventsRequested()),
          ),
          const DebugMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<OrganizerEventsBloc, OrganizerEventsState>(
        builder: (context, state) => switch (state) {
          OrganizerEventsLoading() => const LoadingView(),
          OrganizerEventsFailure() => FailureView(onRetry: () => bloc.add(const OrganizerEventsRequested())),
          OrganizerEventsEmpty() => const EmptyView(
            title: 'Nemate nijedan događaj.',
            message: 'Događaji se u ovoj verziji unose unapred.',
          ),
          OrganizerEventsLoaded(:final events) => _EventList(events: events),
        },
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              key: ValueKey(event.id),
              leading: const Icon(Icons.event_outlined),
              title: Text(event.name),
              subtitle: Text('${formatDateTime(event.startsAt)} · ${event.venue} · ${event.capacity} mesta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(EventsScreen.pathFor(event.id)),
            );
          },
        ),
      ),
    );
  }
}
