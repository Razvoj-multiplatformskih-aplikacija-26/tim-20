import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

// F5: table, summary and detail panel. Placeholder until then.
class EventTicketsScreen extends StatelessWidget {
  const EventTicketsScreen({super.key, required this.eventId, this.selectedId});

  final EventId eventId;
  final TicketId? selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Karte'),
      ),
      body: EmptyView(title: 'Karte za događaj ${eventId.value}'),
    );
  }
}
