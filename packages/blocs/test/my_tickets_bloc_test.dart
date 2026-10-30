import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_ticketing.dart';

void main() {
  final nextWeek = event('e-1', startsIn: const Duration(days: 7));
  final tomorrow = event('e-2', startsIn: const Duration(hours: 20));

  final reserved = ticket('t-1', status: Reserved(expiresAt: now.add(reservationHold)));
  final paid = ticket('t-2', status: Paid(paidAt: now));
  final paidTomorrow = ticket(
    't-3',
    status: Paid(paidAt: now),
    event: 'e-2',
  );

  MyTicketsBloc build(FakeTicketing store) => MyTicketsBloc(
    getMyTickets: GetMyTickets(events: store, tickets: store, clock: clock),
    payTicket: PayTicket(tickets: store, clock: clock),
    cancelTicket: CancelTicket(events: store, tickets: store, clock: clock),
    visitor: ana,
    clock: clock,
  );

  FakeTicketing store() => FakeTicketing(events: [nextWeek, tomorrow], tickets: [reserved, paid, paidTomorrow]);

  /// Actions make sense only once the list is on screen, so the tests wait for it like a visitor would.
  Future<void> load(MyTicketsBloc bloc) async {
    bloc.add(const MyTicketsRequested());
    await bloc.stream.firstWhere((s) => s is MyTicketsLoaded);
  }

  group('four states', () {
    blocTest<MyTicketsBloc, MyTicketsState>(
      'requested emits loading, then the tickets sorted by event start',
      build: () => build(store()),
      act: (bloc) => bloc.add(const MyTicketsRequested()),
      expect: () => [
        const MyTicketsLoading(),
        isA<MyTicketsLoaded>().having((s) => s.tickets.map((t) => t.ticket.id.value), 'ids', ['t-3', 't-1', 't-2']),
      ],
    );

    blocTest<MyTicketsBloc, MyTicketsState>(
      'requested on an outage emits failure',
      build: () => build(store()..failingRequests = 1),
      act: (bloc) => bloc.add(const MyTicketsRequested()),
      expect: () => [
        const MyTicketsLoading(),
        isA<MyTicketsFailure>().having((s) => s.cause, 'cause', isA<RepositoryException>()),
      ],
    );

    blocTest<MyTicketsBloc, MyTicketsState>(
      'a visitor without tickets gets empty',
      build: () => build(FakeTicketing(events: [nextWeek])),
      act: (bloc) => bloc.add(const MyTicketsRequested()),
      expect: () => [const MyTicketsLoading(), const MyTicketsEmpty()],
    );
  });

  blocTest<MyTicketsBloc, MyTicketsState>(
    'filter Plaćena keeps only paid tickets, and is not the empty state when nothing matches',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc
        ..add(const MyTicketsFilterChanged(StatusFilter.paid))
        ..add(const MyTicketsFilterChanged(StatusFilter.used));
    },
    skip: 2,
    expect: () => [
      isA<MyTicketsLoaded>().having((s) => s.filter, 'filter', StatusFilter.paid).having(
        (s) => s.visible.map((t) => t.ticket.id.value),
        'visible',
        ['t-3', 't-2'],
      ),
      isA<MyTicketsLoaded>().having((s) => s.visible, 'visible', isEmpty),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'pay marks the ticket in flight, then reloads with a paid notice',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc.add(const TicketPaymentRequested(TicketId('t-1')));
    },
    skip: 2,
    expect: () => [
      isA<MyTicketsLoaded>()
          .having((s) => s.inFlightId, 'inFlight', const TicketId('t-1'))
          .having((s) => s.isBusy, 'busy', isTrue),
      isA<MyTicketsLoaded>()
          .having((s) => s.byId(const TicketId('t-1'))?.ticket.status, 'status', Paid(paidAt: now))
          .having((s) => s.notice, 'notice', isA<TicketPaid>())
          .having((s) => s.inFlightId, 'inFlight', isNull),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'a cancellation that is too late is rejected with the domain error and nothing changes',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc.add(const TicketCancellationRequested(TicketId('t-3')));
    },
    skip: 3,
    expect: () => [
      isA<MyTicketsLoaded>()
          .having((s) => s.notice, 'notice', const TicketActionRejected(CancellationTooLate()))
          .having((s) => s.byId(const TicketId('t-3'))?.ticket.status, 'status', Paid(paidAt: now))
          .having((s) => s.inFlightId, 'inFlight', isNull),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'a second action while one is in flight is ignored',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc
        ..add(const TicketPaymentRequested(TicketId('t-1')))
        ..add(const TicketCancellationRequested(TicketId('t-2')));
    },
    skip: 2,
    expect: () => [
      isA<MyTicketsLoaded>().having((s) => s.inFlightId, 'inFlight', const TicketId('t-1')),
      isA<MyTicketsLoaded>()
          .having((s) => s.notice, 'notice', isA<TicketPaid>())
          .having((s) => s.byId(const TicketId('t-2'))?.ticket.status, 'status', Paid(paidAt: now)),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'a filter change while an action is in flight keeps the busy guard and the new filter',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc
        ..add(const TicketPaymentRequested(TicketId('t-1')))
        ..add(const MyTicketsFilterChanged(StatusFilter.paid));
    },
    skip: 2,
    expect: () => [
      isA<MyTicketsLoaded>().having((s) => s.inFlightId, 'inFlight', const TicketId('t-1')),
      isA<MyTicketsLoaded>()
          .having((s) => s.inFlightId, 'inFlight', const TicketId('t-1'))
          .having((s) => s.filter, 'filter', StatusFilter.paid)
          .having((s) => s.isBusy, 'busy', isTrue),
      isA<MyTicketsLoaded>()
          .having((s) => s.filter, 'filter', StatusFilter.paid)
          .having((s) => s.notice, 'notice', isA<TicketPaid>())
          .having((s) => s.inFlightId, 'inFlight', isNull),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'the loaded state remembers when the tickets were read',
    build: () => build(store()),
    act: (bloc) => bloc.add(const MyTicketsRequested()),
    skip: 1,
    expect: () => [isA<MyTicketsLoaded>().having((s) => s.loadedAt, 'loadedAt', now)],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'an outage during cancel reports a failed action and keeps the tickets',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      (bloc.cancelTicket.tickets as FakeTicketing).failingRequests = 1;
      bloc.add(const TicketCancellationRequested(TicketId('t-2')));
    },
    skip: 3,
    expect: () => [
      isA<MyTicketsLoaded>()
          .having((s) => s.notice, 'notice', isA<TicketActionFailed>())
          .having((s) => s.tickets, 'tickets', hasLength(3))
          .having((s) => s.inFlightId, 'inFlight', isNull),
    ],
  );

  blocTest<MyTicketsBloc, MyTicketsState>(
    'acknowledging the notice clears it',
    build: () => build(store()),
    act: (bloc) async {
      await load(bloc);
      bloc.add(const TicketPaymentRequested(TicketId('t-1')));
      await bloc.stream.firstWhere((s) => s is MyTicketsLoaded && s.notice != null);
      bloc.add(const MyTicketsNoticeAcknowledged());
    },
    skip: 4,
    expect: () => [isA<MyTicketsLoaded>().having((s) => s.notice, 'notice', isNull)],
  );
}
