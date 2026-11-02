import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({super.key, required this.selected, required this.onSelected});

  final StatusFilter selected;
  final ValueChanged<StatusFilter> onSelected;

  static String labelOf(StatusFilter filter) => switch (filter) {
    StatusFilter.all => 'Sve',
    StatusFilter.reserved => 'Rezervisane',
    StatusFilter.paid => 'Plaćene',
    StatusFilter.used => 'Iskorišćene',
    StatusFilter.cancelled => 'Otkazane',
    StatusFilter.expired => 'Istekle',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final filter in StatusFilter.values) ...[
            ChoiceChip(
              label: Text(labelOf(filter)),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
