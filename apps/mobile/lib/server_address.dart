import 'package:flutter/foundation.dart';

/// The Android emulator reaches the host through 10.0.2.2; a phone on Wi-Fi passes SERVER_URL with --dart-define.
Uri serverAddress() {
  const configured = String.fromEnvironment('SERVER_URL');
  if (configured.isNotEmpty) return Uri.parse(configured);
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  return Uri.parse('http://$host:8080');
}
