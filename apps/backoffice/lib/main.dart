import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// F4: app.dart, dependencies.dart, router.dart. Placeholder until then.
void main() => runApp(const BackofficeApp());

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulaznice · organizator',
      theme: TicketsTheme.light(),
      darkTheme: TicketsTheme.dark(),
      home: const Scaffold(body: EmptyView(title: 'Ulaznice · organizator')),
    );
  }
}
