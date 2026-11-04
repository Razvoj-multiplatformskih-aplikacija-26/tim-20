import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../text.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.id});

  final EventId id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        final listing = switch (state) {
          EventsLoading() || EventsFailure() || EventsEmpty() => null,
          EventsLoaded(:final events) => events.where((listing) => listing.event.id == id).firstOrNull,
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Događaj')),
          body: switch (state) {
            EventsLoading() => const LoadingView(),
            EventsFailure() => FailureView(onRetry: () => context.read<EventsBloc>().add(const EventsRequested())),
            EventsEmpty() || EventsLoaded() =>
              listing == null ? const EmptyView(title: 'Događaj nije pronađen.') : _Details(listing: listing),
          },
          bottomNavigationBar: listing == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: listing.remaining == 0 ? null : () => context.push('/dogadjaj/${id.value}/kupovina'),
                    child: Text(listing.remaining == 0 ? 'Rasprodato' : 'Kupi karte'),
                  ),
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.listing});

  final EventListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = listing.event;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Semantics(header: true, child: Text(event.name, style: theme.textTheme.headlineMedium)),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _DetailRow(icon: Icons.schedule_outlined, label: 'Početak', value: formatDateTime(event.startsAt)),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.place_outlined, label: 'Mesto', value: event.venue),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.payments_outlined, label: 'Cena karte', value: priceLabel(event.priceRsd)),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(
                icon: Icons.event_seat_outlined,
                label: 'Slobodna mesta',
                value: remainingLabel(listing.remaining),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: theme.textTheme.titleMedium),
    );
  }
}
