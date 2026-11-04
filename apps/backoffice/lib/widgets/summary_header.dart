import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key, required this.event, required this.summary});

  final Event event;
  final TicketSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatDateTime(event.startsAt)} · ${event.venue} · ${formatRsd(event.priceRsd)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Stat(label: 'Prodato', value: '${summary.sold} / ${summary.capacity}'),
              _Stat(label: 'Popunjenost', value: '${(summary.occupancy * 100).round()}%'),
              _Stat(label: 'Ušlo', value: '${summary.entered}'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: summary.occupancy.clamp(0, 1), minHeight: 6),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}
