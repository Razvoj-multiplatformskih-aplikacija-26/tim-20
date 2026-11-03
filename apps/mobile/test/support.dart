import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

/// Wednesday 4. 11. 2026. at 13:00 in Belgrade; the seed is relative to it.
final wednesdayNoon = DateTime.utc(2026, 11, 4, 12);

AppDependencies fakeDependencies({DateTime? now, Duration latency = Duration.zero}) =>
    AppDependencies.fake(clock: FixedClock(now ?? wednesdayNoon), latency: latency);

Widget appWith(AppDependencies dependencies, {String initialLocation = '/'}) =>
    MobileApp(dependencies: dependencies, initialLocation: initialLocation);

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(const Duration(milliseconds: 100));

void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Finder appBarTitle(String title) => find.descendant(of: find.byType(AppBar), matching: find.text(title));

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}
