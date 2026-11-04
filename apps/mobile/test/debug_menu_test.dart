import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('the debug menu arms the fake for one failing request', (tester) async {
    usePhoneSize(tester);
    final dependencies = fakeDependencies();
    await tester.pumpWidget(appWith(dependencies));
    await settle(tester);

    await tester.tap(find.byTooltip('Simulacija'));
    await settle(tester);
    await tester.tap(find.text('Simuliraj grešku'));
    await settle(tester);

    expect(dependencies.fake!.failingRequests, 1);
    expect(dependencies.fake!.emptyResponses, 0);
    expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
