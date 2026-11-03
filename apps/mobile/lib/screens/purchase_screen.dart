import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// D6: the purchase form. Placeholder until then.
class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key, required this.id});

  final EventId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kupovina')),
      body: EmptyView(title: 'Uskoro.', message: id.value),
    );
  }
}
