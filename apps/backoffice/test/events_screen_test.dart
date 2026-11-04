import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  testWidgets('the event list shows loading, data, failure with retry, and empty', (tester) async {
    await pumpBackoffice(tester);
    expect(find.byType(LoadingView), findsOneWidget);

    await settle(tester);
    expect(find.text('Brucošijada'), findsOneWidget);
    expect(find.text('Stand-up veče'), findsOneWidget);
    expect(find.text('Radionica 3D štampe'), findsOneWidget);

    await tester.tap(find.byTooltip('Simuliraj grešku'));
    await tester.tap(find.byTooltip('Osveži'));
    await settle(tester);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.text('Brucošijada'), findsOneWidget);

    await tester.tap(find.byTooltip('Simuliraj prazan odgovor'));
    await tester.tap(find.byTooltip('Osveži'));
    await settle(tester);
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('tapping an event opens its tickets at its own address', (tester) async {
    await pumpBackoffice(tester);
    await settle(tester);

    await tester.tap(find.text('Brucošijada'));
    await settle(tester);

    expect(currentLocation(tester), '/dogadjaji/e-a');
  });
}
