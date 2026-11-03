import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// D7: ticket details with the QR code, pay and cancel. Placeholder until then.
class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key, required this.id});

  final TicketId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karta')),
      body: EmptyView(title: 'Uskoro.', message: id.value),
    );
  }
}
