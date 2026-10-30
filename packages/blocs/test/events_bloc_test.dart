import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_ticketing.dart';

void main() {
  final nextWeek = event('e-1', startsIn: const Duration(days: 7));

  EventsBloc build(FakeTicketing store) => EventsBloc(GetUpcomingEvents(events: store, tickets: store, clock: clock));

  blocTest<EventsBloc, EventsState>(
    'requested emits loading, then the events with their free seats',
    build: () => build(
      FakeTicketing(
        events: [nextWeek],
        tickets: [ticket('t-1', status: Paid(paidAt: now))],
      ),
    ),
    act: (bloc) => bloc.add(const EventsRequested()),
    expect: () => [
      const EventsLoading(),
      EventsLoaded([EventListing(event: nextWeek, remaining: 9)]),
    ],
  );

  blocTest<EventsBloc, EventsState>(
    'requested on an outage emits failure, and a retry loads the events',
    build: () => build(FakeTicketing(events: [nextWeek])..failingRequests = 1),
    act: (bloc) => bloc
      ..add(const EventsRequested())
      ..add(const EventsRequested()),
    expect: () => [
      const EventsLoading(),
      isA<EventsFailure>().having((s) => s.cause, 'cause', isA<RepositoryException>()),
      const EventsLoading(),
      EventsLoaded([EventListing(event: nextWeek, remaining: 10)]),
    ],
  );

  blocTest<EventsBloc, EventsState>(
    'no upcoming events emits empty',
    build: () => build(FakeTicketing(events: [event('e-old', startsIn: const Duration(days: -1))])),
    act: (bloc) => bloc.add(const EventsRequested()),
    expect: () => [const EventsLoading(), const EventsEmpty()],
  );
}
