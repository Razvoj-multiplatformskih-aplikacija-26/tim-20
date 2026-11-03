import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';

// D6: the list of upcoming events. Placeholder until then.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Događaji'), actions: [if (kDebugMode) const DebugMenu()]),
      body: const EmptyView(title: 'Uskoro.'),
    );
  }
}
