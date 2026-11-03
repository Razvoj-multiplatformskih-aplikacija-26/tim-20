import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// The table for a narrow window. Scrolls to the selected ticket when it first appears, so narrowing loses nothing.
class TicketList extends StatefulWidget {
  const TicketList({
    super.key,
    required this.tickets,
    required this.cursor,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Ticket> tickets;
  final int? cursor;
  final TicketId? selectedId;
  final ValueChanged<Ticket> onSelect;

  @override
  State<TicketList> createState() => _TicketListState();
}

class _TicketListState extends State<TicketList> {
  final _target = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _target.currentContext;
      if (target != null && target.mounted) Scrollable.ensureVisible(target, alignment: 0.5);
    });
  }

  int? get _targetIndex {
    final selected = widget.tickets.indexWhere((t) => t.id == widget.selectedId);
    return selected >= 0 ? selected : widget.cursor;
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.tickets;
    if (tickets.isEmpty) return const EmptyView(title: 'Nijedna karta nije u ovom stanju.');
    final target = _targetIndex;
    // Every tile is laid out up front, so the one to scroll to exists even when it is far down the list.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, ticket) in tickets.indexed)
            _TicketTile(
              key: index == target ? _target : ValueKey(ticket.id),
              ticket: ticket,
              selected: ticket.id == widget.selectedId,
              onTap: () => widget.onSelect(ticket),
            ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({super.key, required this.ticket, required this.selected, required this.onTap});

  final Ticket ticket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${ticket.holderName}, ${ticket.code}, ${ticket.status.label}',
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: ListTile(
          onTap: onTap,
          title: Text(ticket.holderName),
          subtitle: Text(ticket.code),
          trailing: StatusBadge(ticket.status),
        ),
      ),
    );
  }
}
