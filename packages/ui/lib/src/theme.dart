import 'package:flutter/material.dart';

// D3: seed, font Inter, TextTheme. Stub until then.
abstract final class TicketsTheme {
  static const _seed = Color(0xFF3949AB);

  static ThemeData light() => ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed));

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  );
}
