import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';
import '../widgets/event_card.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Future<void> _refresh(EventsBloc bloc) {
    bloc.add(const EventsRequested());
    return bloc.stream.firstWhere((state) => state is! EventsLoading);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EventsBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Događaji'), actions: [if (kDebugMode) const DebugMenu()]),
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => _refresh(bloc),
          child: switch (state) {
            EventsLoading() => const LoadingView(),
            EventsFailure() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [FailureView(onRetry: () => bloc.add(const EventsRequested()))],
            ),
            EventsEmpty() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [EmptyView(title: 'Nema predstojećih događaja.')],
            ),
            EventsLoaded(:final events) => ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final listing = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EventCard(listing: listing, onOpen: () => context.push('/dogadjaj/${listing.event.id.value}')),
                );
              },
            ),
          },
        ),
      ),
    );
  }
}
