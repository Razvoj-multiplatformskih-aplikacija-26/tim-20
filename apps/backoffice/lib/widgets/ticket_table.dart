import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class TicketTable extends StatelessWidget {
  const TicketTable({
    super.key,
    required this.tickets,
    required this.cursor,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Ticket> tickets;

  /// Row the keyboard points at, or null when the table has no focus.
  final int? cursor;
  final TicketId? selectedId;
  final ValueChanged<Ticket> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tickets.isEmpty) return const EmptyView(title: 'Nijedna karta nije u ovom stanju.');
    return Column(
      children: [
        _Row(
          cells: [
            for (final title in const ['Posetilac', 'Kôd', 'Stanje', 'Kupljeno', 'Ušao'])
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketRow(
                key: ValueKey(ticket.id),
                ticket: ticket,
                selected: ticket.id == selectedId,
                atCursor: index == cursor,
                onTap: () => onSelect(ticket),
              );
            },
          ),
        ),
      ],
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
