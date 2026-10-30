import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// D5: app.dart, dependencies.dart, router.dart. Placeholder until then.
void main() => runApp(const MobileApp());

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulaznice',
      theme: TicketsTheme.light(),
      darkTheme: TicketsTheme.dark(),
      home: const Scaffold(body: EmptyView(title: 'Ulaznice')),
    );
  }
}
