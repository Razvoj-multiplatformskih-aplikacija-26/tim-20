import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../dependencies.dart';
import '../text.dart';
import '../widgets/ticket_tile.dart';
import 'my_tickets_screen.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key, required this.id});

  final TicketId id;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyTicketsBloc>();
    return BlocBuilder<MyTicketsBloc, MyTicketsState>(
      builder: (context, state) {
        final owned = switch (state) {
          MyTicketsLoading() || MyTicketsFailure() || MyTicketsEmpty() => null,
          MyTicketsLoaded() => state.byId(id),
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Karta')),
          body: switch (state) {
            MyTicketsLoading() => const LoadingView(),
            MyTicketsFailure() => FailureView(onRetry: () => bloc.add(const MyTicketsRequested())),
            MyTicketsEmpty() => const EmptyView(title: 'Karta nije pronađena.'),
            MyTicketsLoaded(:final loadedAt) =>
              owned == null ? const EmptyView(title: 'Karta nije pronađena.') : _Details(owned: owned, now: loadedAt),
          },
          bottomNavigationBar: owned == null || state is! MyTicketsLoaded
              ? null
              : _Actions(
                  owned: owned,
                  busy: state.inFlightId == id,
                  onPay: owned.actions.contains(VisitorAction.pay) && !state.isBusy
                      ? () => bloc.add(TicketPaymentRequested(id))
                      : null,
                  onCancel: owned.actions.contains(VisitorAction.cancel) && !state.isBusy
                      ? () => confirmCancellation(context, owned.ticket)
                      : null,
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.owned, required this.now});

  final OwnedTicket owned;

  /// The moment the actions were decided, so the note agrees with them.
  final DateTime now;

  /// Why an active ticket cannot be cancelled: the same rule the bloc would run, asked only for its error.
  String? _cancellationNote(BuildContext context) {
    if (owned.actions.contains(VisitorAction.cancel) || !owned.ticket.status.isActive) return null;
    final visitor = context.read<AppDependencies>().visitor;
    final result = cancelTicket(owned.ticket, owned.event, by: visitor, now: now);
    return switch (result) {
      Success() => null,
      Failure(:final error) => error.message,
    };
  }

  List<Widget> _statusRows(TicketStatus status) => switch (status) {
    Reserved(:final expiresAt) => [
      _DetailRow(icon: Icons.hourglass_bottom_outlined, label: 'Platiti do', value: formatDateTime(expiresAt)),
    ],
    Paid(:final paidAt) => [
      _DetailRow(icon: Icons.check_circle_outline, label: 'Plaćena', value: formatDateTime(paidAt)),
    ],
    Used(:final scannedAt) => [
      _DetailRow(icon: Icons.login_outlined, label: 'Skenirana na ulazu', value: formatDateTime(scannedAt)),
    ],
    Cancelled(:final at, :final reason) => [
      _DetailRow(
        icon: Icons.cancel_outlined,
        label: 'Otkazana',
        value: reason.isEmpty ? formatDateTime(at) : '${formatDateTime(at)} · $reason',
      ),
    ],
    Expired(:final at) => [_DetailRow(icon: Icons.timer_off_outlined, label: 'Istekla', value: formatDateTime(at))],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ticket = owned.ticket;
    final event = owned.event;
    final note = _cancellationNote(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(header: true, child: Text(event.name, style: theme.textTheme.headlineMedium)),
            ),
            const SizedBox(width: 12),
            Padding(padding: const EdgeInsets.only(top: 6), child: StatusBadge(ticket.status)),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(note, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: ticket.code,
                    size: 200,
                    semanticsLabel: 'QR kod karte',
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(ticket.code, style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _DetailRow(icon: Icons.schedule_outlined, label: 'Početak', value: formatDateTime(event.startsAt)),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.place_outlined, label: 'Mesto', value: event.venue),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.payments_outlined, label: 'Cena', value: priceLabel(event.priceRsd)),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.person_outline, label: 'Vlasnik', value: ticket.holderName),
              const Divider(indent: 16, endIndent: 16),
              ..._statusRows(ticket.status),
              const Divider(indent: 16, endIndent: 16),
              _DetailRow(icon: Icons.shopping_bag_outlined, label: 'Kupljena', value: formatDateTime(ticket.createdAt)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.owned, required this.busy, required this.onPay, required this.onCancel});

  final OwnedTicket owned;
  final bool busy;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (!busy && onPay == null && onCancel == null) return const SizedBox.shrink();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: busy
          ? const Center(heightFactor: 1, child: ActionProgress())
          : Row(
              children: [
                if (onCancel case final cancel?)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: cancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Otkaži'),
                    ),
                  ),
                if (onCancel != null && onPay != null) const SizedBox(width: 12),
                if (onPay case final pay?)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: pay,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Plati'),
                    ),
                  ),
              ],
            ),
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
