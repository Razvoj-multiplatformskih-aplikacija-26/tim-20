import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class TicketTile extends StatelessWidget {
  const TicketTile({
    super.key,
    required this.owned,
    required this.onOpen,
    this.onPay,
    this.onCancel,
    this.busy = false,
  });

  final OwnedTicket owned;
  final VoidCallback onOpen;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final event = owned.event;
    final status = owned.ticket.status;
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(formatDateTime(event.startsAt), style: muted),
                          Text(event.venue, style: muted),
                          if (status case Reserved(:final expiresAt)) ...[
                            const SizedBox(height: 4),
                            Text('Platite do ${formatDateTime(expiresAt)}.', style: muted),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(status),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (busy)
                    const ActionProgress()
                  else ...[
                    if (onCancel case final cancel?) TextButton(onPressed: cancel, child: const Text('Otkaži')),
                    if (onPay case final pay?) ...[
                      const SizedBox(width: 8),
                      FilledButton.tonal(onPressed: pay, child: const Text('Plati')),
                    ],
                    if (onCancel == null && onPay == null) const SizedBox(height: 40),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionProgress extends StatelessWidget {
  const ActionProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Radnja u toku',
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: Text(
                'U toku…',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
