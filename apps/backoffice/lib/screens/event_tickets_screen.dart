import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../shortcuts.dart';
import '../widgets/debug_menu.dart';
import '../widgets/shortcuts_overview.dart';
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
  final _tableFocus = FocusNode(debugLabel: 'ticket table');

  EventTicketsBloc get _bloc => context.read<EventTicketsBloc>();

  @override
  void didUpdateWidget(_EventTicketsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _syncWithRoute();
  }

  @override
  void dispose() {
    _tableFocus.dispose();
    super.dispose();
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

  Ticket? get _selected => switch (_bloc.state) {
    EventTicketsLoaded(:final selected) => selected,
    EventTicketsLoading() || EventTicketsFailure() || EventTicketsNotFound() || EventTicketsEmpty() => null,
  };

  bool _selectedAllows(StaffAction action) => switch (_bloc.state) {
    EventTicketsLoaded(:final selected, :final isBusy) && final state =>
      !isBusy && selected != null && state.actionsFor(selected.id).contains(action),
    EventTicketsLoading() || EventTicketsFailure() || EventTicketsNotFound() || EventTicketsEmpty() => false,
  };

  void _confirm() {
    if (_selected case final ticket?) _bloc.add(PaymentConfirmationRequested(ticket.id));
  }

  void _admit() {
    if (_selected case final ticket?) _bloc.add(TicketAdmissionRequested(ticket.id));
  }

  Future<void> _void() async {
    final ticket = _selected;
    if (ticket == null) return;
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
    return Shortcuts(
      shortcuts: ticketShortcuts(),
      child: Actions(
        actions: {
          ConfirmPaymentIntent: GuardedCallbackAction<ConfirmPaymentIntent>(
            enabled: () => _selectedAllows(StaffAction.confirmPayment),
            onInvoke: (_) => _confirm(),
          ),
          AdmitTicketIntent: GuardedCallbackAction<AdmitTicketIntent>(
            enabled: () => _selectedAllows(StaffAction.admit),
            onInvoke: (_) => _admit(),
          ),
          VoidTicketIntent: GuardedCallbackAction<VoidTicketIntent>(
            enabled: () => _selectedAllows(StaffAction.voidTicket),
            onInvoke: (_) => _void(),
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (_) => bloc.add(const EventTicketsRefreshed())),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) {
              _select(null);
              _tableFocus.requestFocus();
              return null;
            },
          ),
          ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(onInvoke: (_) => showShortcutsOverview(context)),
        },
        child: FocusScope(
          autofocus: true,
          child: BlocListener<EventTicketsBloc, EventTicketsState>(
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
                  IconButton(
                    tooltip: 'Prečice (?)',
                    icon: const Icon(Icons.keyboard_outlined),
                    onPressed: () => showShortcutsOverview(context),
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
                  EventTicketsLoaded() => _LoadedBody(
                    state: state,
                    tableFocus: _tableFocus,
                    onSelect: _select,
                    onConfirm: _confirm,
                    onAdmit: _admit,
                    onVoid: _void,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.tableFocus,
    required this.onSelect,
    required this.onConfirm,
    required this.onAdmit,
    required this.onVoid,
  });

  final EventTicketsLoaded state;
  final FocusNode tableFocus;
  final ValueChanged<Ticket?> onSelect;
  final VoidCallback onConfirm;
  final VoidCallback onAdmit;
  final VoidCallback onVoid;

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
                // The cursor is drawn only while the table has the keyboard, like a focus ring.
                child: ListenableBuilder(
                  listenable: tableFocus,
                  builder: (context, _) => TicketTable(
                    tickets: state.visible,
                    cursor: tableFocus.hasFocus ? state.cursor : null,
                    selectedId: state.selectedId,
                    focusNode: tableFocus,
                    onSelect: onSelect,
                    onCursorMoved: (delta) => bloc.add(TicketCursorMoved(delta)),
                    onActivate: () => bloc.add(const TicketCursorActivated()),
                  ),
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
                    onConfirm: onConfirm,
                    onAdmit: onAdmit,
                    onVoid: onVoid,
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
