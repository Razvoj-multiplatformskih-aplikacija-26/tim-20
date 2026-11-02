import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

class TicketTable extends StatefulWidget {
  const TicketTable({
    super.key,
    required this.tickets,
    required this.cursor,
    required this.selectedId,
    required this.focusNode,
    required this.onSelect,
    required this.onCursorMoved,
    required this.onActivate,
  });

  final List<Ticket> tickets;

  /// Row the keyboard points at, or null when the table has no focus.
  final int? cursor;
  final TicketId? selectedId;
  final FocusNode focusNode;
  final ValueChanged<Ticket> onSelect;
  final ValueChanged<int> onCursorMoved;
  final VoidCallback onActivate;

  @override
  State<TicketTable> createState() => _TicketTableState();
}

class _TicketTableState extends State<TicketTable> {
  final _cursorRow = GlobalKey();

  @override
  void didUpdateWidget(TicketTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cursor != oldWidget.cursor && widget.cursor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCursor());
    }
  }

  void _revealCursor() {
    final row = _cursorRow.currentContext;
    if (row == null || !row.mounted) return;
    Scrollable.ensureVisible(row, alignment: 0.5, duration: const Duration(milliseconds: 150));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        widget.onCursorMoved(-1);
      case LogicalKeyboardKey.arrowDown:
        widget.onCursorMoved(1);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter || LogicalKeyboardKey.space:
        widget.onActivate();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = widget.tickets;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Semantics(
        container: true,
        label: 'Tabela karata, ${tickets.length} redova',
        child: tickets.isEmpty
            ? const EmptyView(title: 'Nijedna karta nije u ovom stanju.')
            : Column(
                children: [
                  _Row(
                    cells: [
                      for (final title in const ['Posetilac', 'Kôd', 'Stanje', 'Kupljeno', 'Ušao'])
                        Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final atCursor = index == widget.cursor;
                        return _TicketRow(
                          key: atCursor ? _cursorRow : ValueKey(ticket.id),
                          ticket: ticket,
                          selected: ticket.id == widget.selectedId,
                          atCursor: atCursor,
                          onTap: () {
                            widget.focusNode.requestFocus();
                            widget.onSelect(ticket);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    super.key,
    required this.ticket,
    required this.selected,
    required this.atCursor,
    required this.onTap,
  });

  final Ticket ticket;
  final bool selected;
  final bool atCursor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = ticket.status;
    final enteredAt = switch (status) {
      Used(:final scannedAt) => formatDateTime(scannedAt),
      Reserved() || Paid() || Cancelled() || Expired() => '—',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${ticket.holderName}, ${status.label}',
      child: InkWell(
        onTap: onTap,
        // The table as a whole owns the keyboard, so Tab does not stop on every row.
        canRequestFocus: false,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            border: Border(
              left: BorderSide(color: atCursor ? scheme.primary : Colors.transparent, width: 3),
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: _Row(
            cells: [
              Text(ticket.holderName),
              Text(ticket.code),
              Align(alignment: Alignment.centerLeft, child: StatusBadge(status)),
              Text(formatDateTime(ticket.createdAt)),
              Text(enteredAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.cells});

  static const _flex = [3, 2, 2, 3, 3];

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [for (final (index, cell) in cells.indexed) Expanded(flex: _flex[index], child: cell)],
      ),
    );
  }
}
