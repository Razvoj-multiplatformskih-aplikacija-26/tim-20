import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  for (final (name, location) in [('events', '/'), ('my tickets', '/karte'), ('ticket detail', '/karte/a-2')]) {
    testWidgets('$name meets the contrast, tap target and label guidelines', (tester) async {
      usePhoneSize(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(appWith(fakeDependencies(), initialLocation: location));
      await settle(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
