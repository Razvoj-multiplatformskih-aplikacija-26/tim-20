import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  testWidgets('events list shows four states', (tester) async {
    usePhoneSize(tester);
    final dependencies = fakeDependencies(latency: const Duration(seconds: 1));
    dependencies.fake!.failingRequests = 1;

    await tester.pumpWidget(appWith(dependencies));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Podaci trenutno nisu dostupni.'), findsOneWidget);

    dependencies.fake!.emptyResponses = 1;
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Nema predstojećih događaja.'), findsOneWidget);

    await tester.fling(find.byType(EmptyView), const Offset(0, 400), 1000);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Brucošijada 2026'), findsOneWidget);
    expect(find.text('Filmsko veče: Matrix'), findsNothing);
  });

  testWidgets('event card shows name, date, venue, price and remaining seats', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);
    final standUp = seedEvents(wednesdayNoon).singleWhere((event) => event.name == 'Stand-up veče');

    expect(find.text('Stand-up veče'), findsOneWidget);
    expect(find.text(formatDateTime(standUp.startsAt)), findsOneWidget);
    expect(find.text('Klub Fest'), findsOneWidget);
    expect(find.text('700 RSD'), findsOneWidget);
    expect(find.text('Još 1 mesto'), findsOneWidget);
  });

  testWidgets('event detail opens from the list and offers the purchase', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await settle(tester);

    await tester.tap(find.text('Hakaton: 24 sata koda'));
    await settle(tester);
    expect(appBarTitle('Događaj'), findsOneWidget);
    expect(find.text('RAF, sala 7'), findsOneWidget);
    expect(find.text('Kupi karte'), findsOneWidget);
  });
}
