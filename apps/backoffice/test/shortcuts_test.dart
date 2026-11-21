import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:backoffice/shortcuts.dart';

void main() {
  test('holding R does not repeat the refresh shortcut on either screen', () {
    for (final shortcuts in [ticketShortcuts(), eventShortcuts()]) {
      final refresh = shortcuts.keys.whereType<SingleActivator>().singleWhere(
        (activator) => activator.trigger == LogicalKeyboardKey.keyR,
      );
      expect(refresh.includeRepeats, isFalse);
    }
  });
}
