import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';

/// Two buttons for the app bar that make the next request fail or come back empty. Debug builds only.
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final fake = context.read<BackofficeDependencies>().fake;
    if (!kDebugMode || fake == null) return const SizedBox.shrink();
    void notify(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Simuliraj grešku',
          icon: const Icon(Icons.cloud_off_outlined),
          onPressed: () {
            fake.failingRequests = 1;
            notify('Sledeći zahtev neće uspeti.');
          },
        ),
        IconButton(
          tooltip: 'Simuliraj prazan odgovor',
          icon: const Icon(Icons.inbox_outlined),
          onPressed: () {
            fake.emptyResponses = 1;
            notify('Sledeći odgovor će biti prazan.');
          },
        ),
      ],
    );
  }
}
