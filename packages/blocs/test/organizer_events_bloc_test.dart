import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'flaky_ticketing.dart';

void main() {
  OrganizerEventsBloc build(FlakyTicketing store) =>
      OrganizerEventsBloc(GetOrganizerEvents(events: store), organizer: organizer);

  group('OrganizerEventsBloc', () {
    blocTest<OrganizerEventsBloc, OrganizerEventsState>(
      'emits loading then the events of the organizer',
      build: () => build(
        FlakyTicketing(
          events: [
            event('e-1'),
            event('e-x', organizerId: ana.id),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const OrganizerEventsRequested()),
      expect: () => [
        const OrganizerEventsLoading(),
        OrganizerEventsLoaded([event('e-1')]),
      ],
    );

    blocTest<OrganizerEventsBloc, OrganizerEventsState>(
      'emits loading then empty when the organizer has no events',
      build: () => build(FlakyTicketing()),
      act: (bloc) => bloc.add(const OrganizerEventsRequested()),
      expect: () => [const OrganizerEventsLoading(), const OrganizerEventsEmpty()],
    );

    blocTest<OrganizerEventsBloc, OrganizerEventsState>(
      'emits loading then failure when the repository throws',
      build: () => build(FlakyTicketing()..failingRequests = 1),
      act: (bloc) => bloc.add(const OrganizerEventsRequested()),
      expect: () => [const OrganizerEventsLoading(), isA<OrganizerEventsFailure>()],
    );
  });
}
