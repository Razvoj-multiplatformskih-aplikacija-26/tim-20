import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';
import '../widgets/status_filter_chips.dart';
import '../widgets/ticket_tile.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  Future<void> _refresh(MyTicketsBloc bloc) {
    bloc.add(const MyTicketsRequested());
    return bloc.stream.firstWhere((state) => state is! MyTicketsLoading);
  }

  void _showNotice(BuildContext context, MyTicketsNotice notice) {
    final message = switch (notice) {
      TicketPaid() => 'Karta je plaćena.',
      TicketCancelled() => 'Karta je otkazana.',
      TicketActionRejected(:final error) => error.message,
      TicketActionFailed() => 'Radnja nije uspela. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<MyTicketsBloc>().add(const MyTicketsNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyTicketsBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moje karte'), actions: [if (kDebugMode) const DebugMenu()]),
      body: BlocConsumer<MyTicketsBloc, MyTicketsState>(
        listenWhen: (previous, current) => current is MyTicketsLoaded && current.notice != null,
        listener: (context, state) => _showNotice(context, (state as MyTicketsLoaded).notice!),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => _refresh(bloc),
          child: switch (state) {
            MyTicketsLoading() => const LoadingView(),
            MyTicketsFailure() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [FailureView(onRetry: () => bloc.add(const MyTicketsRequested()))],
            ),
            MyTicketsEmpty() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [EmptyView(title: 'Nemate karata.', message: 'Izaberite događaj i kupite kartu.')],
            ),
            MyTicketsLoaded(:final visible) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                StatusFilterChips(
                  selected: state.filter,
                  onSelected: (filter) => bloc.add(MyTicketsFilterChanged(filter)),
                ),
                if (visible.isEmpty) const EmptyView(title: 'Nema karata u ovom stanju.'),
                for (final owned in visible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TicketTile(
                      owned: owned,
                      busy: state.inFlightId == owned.ticket.id,
                      onOpen: () => context.push('/karte/${owned.ticket.id.value}'),
                      onPay: owned.actions.contains(VisitorAction.pay) && !state.isBusy
                          ? () => bloc.add(TicketPaymentRequested(owned.ticket.id))
                          : null,
                      onCancel: owned.actions.contains(VisitorAction.cancel) && !state.isBusy
                          ? () => confirmCancellation(context, owned.ticket)
                          : null,
                    ),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// Cancelling cannot be undone, so the visitor confirms it first.
Future<void> confirmCancellation(BuildContext context, Ticket ticket) async {
  final bloc = context.read<MyTicketsBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: const Text('Otkazati kartu?'),
      content: const Text('Ovo ne može da se vrati.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Otkaži kartu')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  bloc.add(TicketCancellationRequested(ticket.id));
}
