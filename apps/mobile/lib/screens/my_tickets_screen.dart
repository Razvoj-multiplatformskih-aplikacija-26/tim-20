import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';
import 'sign_in_screen.dart';
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
      TicketActionFailed(:final cause) => failureMessage(cause),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<MyTicketsBloc>().add(const MyTicketsNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyTicketsBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje karte'),
        actions: [
          if (context.watch<SessionBloc>().state is SignedIn)
            IconButton(tooltip: 'Odjavi se', icon: const Icon(Icons.logout), onPressed: () => confirmLogOut(context)),
          if (kDebugMode) const DebugMenu(),
        ],
      ),
      body: BlocConsumer<MyTicketsBloc, MyTicketsState>(
        listenWhen: (previous, current) => current is MyTicketsLoaded && current.notice != null,
        listener: (context, state) => _showNotice(context, (state as MyTicketsLoaded).notice!),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => _refresh(bloc),
          child: switch (state) {
            MyTicketsSignedOut() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const EmptyView(title: 'Prijavite se da vidite svoje karte.'),
                Center(
                  child: FilledButton(onPressed: () => ensureSignedIn(context), child: const Text('Prijavi se')),
                ),
              ],
            ),
            MyTicketsLoading() => const LoadingView(),
            MyTicketsFailure(:final cause) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [FailureView(cause: cause, onRetry: () => bloc.add(const MyTicketsRequested()))],
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

/// Logging out ends the session on every screen, so the visitor confirms it first.
Future<void> confirmLogOut(BuildContext context) async {
  final session = context.read<SessionBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: const Text('Odjaviti se?'),
      content: const Text('Za kupovinu i pregled karata biće potrebna nova prijava.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Odjavi se')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  session.add(const SessionLogOutRequested());
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
