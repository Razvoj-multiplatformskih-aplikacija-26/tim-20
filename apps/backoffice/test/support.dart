import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

final sundayEvening = DateTime.utc(2026, 11, 1, 18);

BackofficeDependencies fakeDependencies({Duration latency = Duration.zero}) =>
    BackofficeDependencies.fake(clock: FixedClock(sundayEvening), latency: latency);

void useWindow(WidgetTester tester, {required double width, required double height}) {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// Starts the app at [location] and returns right after the first frame, before anything has loaded.
Future<BackofficeDependencies> pumpBackoffice(
  WidgetTester tester, {
  BackofficeDependencies? dependencies,
  String location = '/',
}) async {
  tester.binding.platformDispatcher.defaultRouteNameTestValue = location;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
  final deps = dependencies ?? fakeDependencies();
  // A new key gives a new router, so a second pump in the same test starts at [location] again.
  await tester.pumpWidget(BackofficeApp(key: UniqueKey(), dependencies: deps));
  return deps;
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(const Duration(milliseconds: 100));

String currentLocation(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).routeInformationProvider.value.uri.toString();
