import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool get usesCommandKey => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

/// An action that is enabled only while [enabled] says so, which the shortcut and the button share.
class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

class ConfirmPaymentIntent extends Intent {
  const ConfirmPaymentIntent();
}

class AdmitTicketIntent extends Intent {
  const AdmitTicketIntent();
}

class VoidTicketIntent extends Intent {
  const VoidTicketIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

// Single letters, so nothing collides with the browser's Ctrl+T, Ctrl+W or Ctrl+N.
Map<ShortcutActivator, Intent> ticketShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.keyC): const ConfirmPaymentIntent(),
  const SingleActivator(LogicalKeyboardKey.keyU): const AdmitTicketIntent(),
  const SingleActivator(LogicalKeyboardKey.keyX): const VoidTicketIntent(),
  const SingleActivator(LogicalKeyboardKey.keyR): const RefreshIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
  const CharacterActivator('?'): const ShowShortcutsIntent(),
};

final class ShortcutDescription {
  const ShortcutDescription(this.keys, this.description);

  final String keys;
  final String description;
}

List<ShortcutDescription> shortcutDescriptions() => const [
  ShortcutDescription('↑ ↓', 'Kretanje kroz karte'),
  ShortcutDescription('Enter', 'Otvori kartu pod kursorom'),
  ShortcutDescription('Esc', 'Zatvori detalj'),
  ShortcutDescription('C', 'Potvrdi plaćanje izabrane karte'),
  ShortcutDescription('U', 'Pusti izabranu kartu na ulaz'),
  ShortcutDescription('X', 'Poništi izabranu kartu'),
  ShortcutDescription('R', 'Osveži'),
  ShortcutDescription('?', 'Pregled prečica'),
];
