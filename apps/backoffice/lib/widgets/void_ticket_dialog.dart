import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Asks for a reason. Returns null when the organizer gives up.
Future<String?> showVoidTicketDialog(BuildContext context, Ticket ticket) {
  return showDialog<String>(
    context: context,
    builder: (_) => _VoidTicketDialog(ticket: ticket),
  );
}

class _VoidTicketDialog extends StatefulWidget {
  const _VoidTicketDialog({required this.ticket});

  final Ticket ticket;

  @override
  State<_VoidTicketDialog> createState() => _VoidTicketDialogState();
}

class _VoidTicketDialogState extends State<_VoidTicketDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Poništiti kartu?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.ticket.code}, ${widget.ticket.holderName}. Ovo ne može da se vrati.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Razlog'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Poništi')),
      ],
    );
  }
}
