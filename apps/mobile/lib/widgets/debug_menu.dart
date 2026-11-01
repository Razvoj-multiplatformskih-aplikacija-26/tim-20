import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';

enum _Simulation { outage, emptyAnswer }

/// Arms the fake so that the next request fails or comes back empty. Shown only in debug builds.
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fake;
    if (fake == null) return const SizedBox.shrink();
    return PopupMenuButton<_Simulation>(
      tooltip: 'Simulacija',
      icon: const Icon(Icons.bug_report_outlined),
      onSelected: (simulation) {
        final message = switch (simulation) {
          _Simulation.outage => (fake.failingRequests = 1, 'Sledeći zahtev neće uspeti.').$2,
          _Simulation.emptyAnswer => (fake.emptyResponses = 1, 'Sledeći odgovor biće prazan.').$2,
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _Simulation.outage, child: Text('Simuliraj grešku')),
        PopupMenuItem(value: _Simulation.emptyAnswer, child: Text('Simuliraj prazan odgovor')),
      ],
    );
  }
}
