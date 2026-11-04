import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../status_colors.dart';
import '../text/ticket_status_label.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = theme.statusColors.of(status);
    return Semantics(
      label: 'Stanje: ${status.label}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
          child: Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
        ),
      ),
    );
  }
}
