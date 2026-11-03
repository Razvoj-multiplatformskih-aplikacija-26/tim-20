import 'package:flutter/material.dart';

/// Lifts the value up; the range is wider than the rule allows on purpose, so the rule reports the error.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 9});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = value > min;
    final canIncrease = value < max;
    return Semantics(
      label: 'Broj karata',
      value: '$value',
      increasedValue: canIncrease ? '${value + 1}' : null,
      decreasedValue: canDecrease ? '${value - 1}' : null,
      onIncrease: canIncrease ? () => onChanged(value + 1) : null,
      onDecrease: canDecrease ? () => onChanged(value - 1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            tooltip: 'Manje karata',
            onPressed: canDecrease ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: ExcludeSemantics(
              child: Text('$value', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Više karata',
            onPressed: canIncrease ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
