import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../text.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.listing, required this.onOpen});

  final EventListing listing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final event = listing.event;
    final soldOut = listing.remaining == 0;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      // The whole card is one tappable item for a screen reader: name, time, place, price and seats.
      child: MergeSemantics(
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(formatDateTime(event.startsAt), style: muted),
                Text(event.venue, style: muted),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(priceLabel(event.priceRsd), style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      remainingLabel(listing.remaining),
                      style: theme.textTheme.labelLarge?.copyWith(color: soldOut ? scheme.error : scheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
