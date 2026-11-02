import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.filter,
    required this.summary,
    required this.total,
    required this.onChanged,
  });

  final StatusFilter filter;
  final TicketSummary summary;
  final int total;
  final ValueChanged<StatusFilter> onChanged;

  String _label(StatusFilter filter) => switch (filter) {
    StatusFilter.all => 'Sve',
    StatusFilter.reserved => 'Rezervisana',
    StatusFilter.paid => 'Plaćena',
    StatusFilter.used => 'Iskorišćena',
    StatusFilter.cancelled => 'Otkazana',
    StatusFilter.expired => 'Istekla',
  };

  int _count(StatusFilter filter) => switch (filter) {
    StatusFilter.all => total,
    StatusFilter.reserved => summary.reserved,
    StatusFilter.paid => summary.paid,
    StatusFilter.used => summary.used,
    StatusFilter.cancelled => summary.cancelled,
    StatusFilter.expired => summary.expired,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in StatusFilter.values)
            ChoiceChip(
              label: Text(_label(value)),
              avatar: Text('${_count(value)}', style: Theme.of(context).textTheme.labelSmall),
              selected: value == filter,
              onSelected: (_) => onChanged(value),
            ),
        ],
      ),
    );
  }
}
