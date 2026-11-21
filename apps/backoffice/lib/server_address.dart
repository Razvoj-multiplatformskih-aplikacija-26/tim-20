import 'package:flutter/foundation.dart';

/// The server on this computer by default; another address comes with --dart-define=SERVER_URL=….
Uri serverAddress() {
  const configured = String.fromEnvironment('SERVER_URL');
  if (configured.isNotEmpty) return Uri.parse(configured);
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  return Uri.parse('http://$host:8080');
}
