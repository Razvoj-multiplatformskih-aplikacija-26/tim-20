import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/ticket_status_label.dart';

// D3: a color for every status. Stub until then.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: TextStyle(color: scheme.onSecondaryContainer)),
    );
  }
}
