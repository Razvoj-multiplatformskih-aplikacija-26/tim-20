import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../widgets/debug_menu.dart';
import '../widgets/status_filter_bar.dart';
import '../widgets/summary_header.dart';
import '../widgets/ticket_detail_panel.dart';
import '../widgets/ticket_table.dart';
import '../widgets/void_ticket_dialog.dart';

/// The bloc lives with the route, so a change of `?selected=` keeps it while the screen below syncs with the address.
class EventTicketsScreen extends StatelessWidget {
  const EventTicketsScreen({super.key, required this.eventId, this.selectedId});

  final EventId eventId;
  final TicketId? selectedId;

  static String pathFor(EventId eventId, {TicketId? selected}) =>
      selected == null ? '/dogadjaji/${eventId.value}' : '/dogadjaji/${eventId.value}?selected=${selected.value}';

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<BackofficeDependencies>();
    return BlocProvider(
      create: (_) => EventTicketsBloc(
        getEventTickets: dependencies.getEventTickets,
        confirmPayment: dependencies.confirmPayment,
        admitTicket: dependencies.admitTicket,
        voidTicket: dependencies.voidTicket,
        staff: dependencies.staff,
      )..add(EventTicketsRequested(eventId, selectedId: selectedId)),
      child: _EventTicketsView(eventId: eventId, selectedId: selectedId),
    );
  }
}

class _EventTicketsView extends StatefulWidget {
  const _EventTicketsView({required this.eventId, required this.selectedId});

  final EventId eventId;
  final TicketId? selectedId;

  @override
  State<_EventTicketsView> createState() => _EventTicketsViewState();
}

class _EventTicketsViewState extends State<_EventTicketsView> {
  EventTicketsBloc get _bloc => context.read<EventTicketsBloc>();

  @override
  void didUpdateWidget(_EventTicketsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _syncWithRoute();
  }

  // The address is the second owner of the selection: refresh in the browser and the back button go through it.
  void _syncWithRoute() {
    final state = _bloc.state;
    if (state is EventTicketsLoaded && state.selectedId != widget.selectedId) {
      _bloc.add(TicketSelected(widget.selectedId));
    }
  }

  void _goTo({TicketId? selected}) => context.go(EventTicketsScreen.pathFor(widget.eventId, selected: selected));

  void _select(Ticket? ticket) => _bloc.add(TicketSelected(ticket?.id));

  Future<void> _void(Ticket ticket) async {
    final reason = await showVoidTicketDialog(context, ticket);
    if (!mounted || reason == null) return;
    _bloc.add(TicketVoidRequested(ticket.id, reason: reason.trim()));
  }

  void _showNotice(BuildContext context, EventTicketsNotice notice) {
    final message = switch (notice) {
      StaffActionSucceeded(:final action) => switch (action) {
        StaffAction.confirmPayment => 'Plaćanje je potvrđeno.',
        StaffAction.admit => 'Karta je puštena na ulaz.',
        StaffAction.voidTicket => 'Karta je poništena.',
      },
      StaffActionRejected(:final error) => error.message,
      StaffActionFailed() => 'Izmena nije sačuvana.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _bloc.add(const EventTicketsNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    return BlocListener<EventTicketsBloc, EventTicketsState>(
      listenWhen: (previous, current) =>
          current is EventTicketsLoaded &&
          (previous is! EventTicketsLoaded || previous.selectedId != current.selectedId),
      listener: (context, state) {
        final selectedId = (state as EventTicketsLoaded).selectedId;
        if (selectedId != widget.selectedId) _goTo(selected: selectedId);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/')),
          title: BlocBuilder<EventTicketsBloc, EventTicketsState>(
            builder: (context, state) => Text(switch (state) {
              EventTicketsLoaded(:final data) => data.event.name,
              EventTicketsEmpty(:final event) => event.name,
              EventTicketsLoading() || EventTicketsFailure() || EventTicketsNotFound() => 'Karte',
            }),
          ),
          actions: [
            IconButton(
              tooltip: 'Osveži (R)',
              icon: const Icon(Icons.refresh),
              onPressed: () => bloc.add(const EventTicketsRefreshed()),
            ),
            const DebugMenu(),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocConsumer<EventTicketsBloc, EventTicketsState>(
          listenWhen: (previous, current) => current is EventTicketsLoaded && current.notice != null,
          listener: (context, state) => _showNotice(context, (state as EventTicketsLoaded).notice!),
          builder: (context, state) => switch (state) {
            EventTicketsLoading() => const LoadingView(),
            EventTicketsFailure() => FailureView(
              onRetry: () => bloc.add(EventTicketsRequested(widget.eventId, selectedId: widget.selectedId)),
            ),
            EventTicketsNotFound() => const EmptyView(title: 'Događaj nije pronađen.'),
            EventTicketsEmpty(:final event) => EmptyView(
              title: 'Još nema karata za ovaj događaj.',
              message: '${event.capacity} mesta · ${formatDateTime(event.startsAt)}',
            ),
            EventTicketsLoaded() => _LoadedBody(state: state, onSelect: _select, onVoid: _void),
          },
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state, required this.onSelect, required this.onVoid});

  final EventTicketsLoaded state;
  final ValueChanged<Ticket?> onSelect;
  final ValueChanged<Ticket> onVoid;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EventTicketsBloc>();
    final data = state.data;
    final selected = state.selected;
    return Column(
      children: [
        if (state.isBusy) const LinearProgressIndicator(minHeight: 3) else const SizedBox(height: 3),
        SummaryHeader(event: data.event, summary: data.summary),
        StatusFilterBar(
          filter: state.filter,
          summary: data.summary,
          total: data.tickets.length,
          onChanged: (filter) => bloc.add(TicketStatusFilterChanged(filter)),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TicketTable(
                  tickets: state.visible,
                  cursor: state.cursor,
                  selectedId: state.selectedId,
                  onSelect: onSelect,
                ),
              ),
              if (selected != null) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 340,
                  child: TicketDetailPanel(
                    ticket: selected,
                    actions: state.actionsFor(selected.id),
                    busy: state.isBusy,
                    onConfirm: () => bloc.add(PaymentConfirmationRequested(selected.id)),
                    onAdmit: () => bloc.add(TicketAdmissionRequested(selected.id)),
                    onVoid: () => onVoid(selected),
                    onClose: () => onSelect(null),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
