import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../widgets/debug_menu.dart';

// D7: the visitor's tickets with the status filter. Placeholder until then.
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje karte'), actions: [if (kDebugMode) const DebugMenu()]),
      body: const EmptyView(title: 'Uskoro.'),
    );
  }
}
