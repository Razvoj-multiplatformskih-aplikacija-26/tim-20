import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// D6: event details with the purchase button. Placeholder until then.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.id});

  final EventId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Događaj')),
      body: EmptyView(title: 'Uskoro.', message: id.value),
    );
  }
}
