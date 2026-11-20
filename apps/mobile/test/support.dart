import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/seed.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

/// Wednesday 4. 11. 2026. at 13:00 in Belgrade; the seed is relative to it.
final wednesdayNoon = DateTime.utc(2026, 11, 4, 12);

AppDependencies fakeDependencies({
  DateTime? now,
  Clock? clock,
  Duration latency = Duration.zero,
  bool signedIn = true,
  User user = ana,
}) => AppDependencies.fake(
  clock: clock ?? FixedClock(now ?? wednesdayNoon),
  latency: latency,
  signedIn: signedIn,
  user: user,
);

/// Another visitor who takes the last seats while Ana is still looking at the old number.
const otherVisitor = User(id: UserId('u-jovan'), name: 'Jovan Jovanović', role: Role.visitor);

/// A clock the test can move forward, to act after a reservation has run out.
final class MovingClock implements Clock {
  MovingClock(this.instant);

  DateTime instant;

  @override
  DateTime now() => instant;
}

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

/// The indicator waits for its drag animation before it asks for data, so the frames are pumped one by one.
Future<void> pullToRefresh(WidgetTester tester, Finder from) async {
  await tester.fling(from, const Offset(0, 400), 1000);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
