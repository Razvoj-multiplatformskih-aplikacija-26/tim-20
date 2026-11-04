import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'flaky_ticketing.dart';

void main() {
  final concert = event('e-1');
  final reserved = ticket('t-1');
  final paid = ticket('t-2', status: Paid(paidAt: now));
  final used = ticket(
    't-3',
    status: Used(scannedAt: now, scannedBy: organizer.id),
  );

  late FlakyTicketing store;
  late MovableClock movable;

  EventTicketsBloc build({List<Event>? events, List<Ticket>? tickets}) {
    movable = MovableClock(now);
    final Clock clock = movable;
    store = FlakyTicketing(
      events: events ?? [concert, event('e-2'), event('e-3')],
      tickets: tickets ?? [reserved, paid, used, ticket('t-9', event: 'e-3')],
    );
    return EventTicketsBloc(
      getEventTickets: GetEventTickets(events: store, tickets: store, clock: clock),
      confirmPayment: ConfirmPayment(tickets: store, clock: clock),
      admitTicket: AdmitTicket(tickets: store, clock: clock),
      voidTicket: VoidTicket(events: store, tickets: store, clock: clock),
      staff: organizer,
    );
  }

  Future<void> loaded(EventTicketsBloc bloc, {TicketId? selectedId}) {
    bloc.add(EventTicketsRequested(concert.id, selectedId: selectedId));
    return bloc.stream.firstWhere((s) => s is EventTicketsLoaded);
  }

  group('loading', () {
    blocTest<EventTicketsBloc, EventTicketsState>(
      'emits loading then loaded with the cursor on the first ticket',
      build: build,
      act: (bloc) => bloc.add(EventTicketsRequested(concert.id)),
      expect: () => [
        const EventTicketsLoading(),
        isA<EventTicketsLoaded>()
            .having((s) => s.data.tickets, 'tickets', [reserved, paid, used])
            .having((s) => s.cursor, 'cursor', 0)
            .having((s) => s.selectedId, 'selected', isNull),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'emits loading then failure when the repository throws',
      build: build,
      act: (bloc) {
        store.failingRequests = 1;
        bloc.add(EventTicketsRequested(concert.id));
      },
      expect: () => [const EventTicketsLoading(), isA<EventTicketsFailure>()],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'emits loading then empty for an event without tickets',
      build: build,
      act: (bloc) => bloc.add(const EventTicketsRequested(EventId('e-2'))),
      expect: () => [const EventTicketsLoading(), EventTicketsEmpty(event('e-2'))],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'emits loading then not found for an unknown event',
      build: build,
      act: (bloc) => bloc.add(const EventTicketsRequested(EventId('missing'))),
      expect: () => [const EventTicketsLoading(), const EventTicketsNotFound()],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'opens the ticket named in the request and puts the cursor on it',
      build: build,
      act: (bloc) => bloc.add(EventTicketsRequested(concert.id, selectedId: paid.id)),
      skip: 1,
      expect: () => [
        isA<EventTicketsLoaded>().having((s) => s.selected, 'selected', paid).having((s) => s.cursor, 'cursor', 1),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'ignores a selected id that names no ticket of the event',
      build: build,
      act: (bloc) => bloc.add(EventTicketsRequested(concert.id, selectedId: const TicketId('missing'))),
      skip: 1,
      expect: () => [isA<EventTicketsLoaded>().having((s) => s.selectedId, 'selected', isNull)],
    );
  });

  group('cursor and selection', () {
    blocTest<EventTicketsBloc, EventTicketsState>(
      'moves within the visible tickets and stops at both ends',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(const TicketCursorMoved(-1))
          ..add(const TicketCursorMoved(1))
          ..add(const TicketCursorMoved(100));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>().having((s) => s.cursor, 'cursor', 1),
        isA<EventTicketsLoaded>().having((s) => s.cursor, 'cursor', 2),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'activating the cursor selects the ticket under it',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(const TicketCursorMoved(1))
          ..add(const TicketCursorActivated());
      },
      skip: 3,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.selected, 'selected', paid)
            .having((s) => s.atCursor, 'at cursor', paid),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'selecting a ticket moves the cursor to it, and null closes the selection',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(TicketSelected(used.id))
          ..add(const TicketSelected(null));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>().having((s) => s.selectedId, 'selected', used.id).having((s) => s.cursor, 'cursor', 2),
        isA<EventTicketsLoaded>().having((s) => s.selectedId, 'selected', isNull).having((s) => s.cursor, 'cursor', 2),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'a filter that hides the selected ticket closes the selection and keeps the cursor on a visible row',
      build: build,
      act: (bloc) async {
        await loaded(bloc, selectedId: used.id);
        bloc.add(const TicketStatusFilterChanged(StatusFilter.reserved));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.visible, 'visible', [reserved])
            .having((s) => s.selectedId, 'selected', isNull)
            .having((s) => s.cursor, 'cursor', 0),
      ],
    );
  });

  group('actions', () {
    blocTest<EventTicketsBloc, EventTicketsState>(
      'confirming a payment marks the ticket in flight, then reloads and reports the success',
      build: build,
      act: (bloc) async {
        await loaded(bloc, selectedId: reserved.id);
        bloc.add(PaymentConfirmationRequested(reserved.id));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.inFlightId, 'in flight', reserved.id)
            .having((s) => s.isBusy, 'busy', isTrue),
        isA<EventTicketsLoaded>()
            .having((s) => s.isBusy, 'busy', isFalse)
            .having((s) => s.selected?.status, 'status', Paid(paidAt: now, confirmedBy: organizer.id))
            .having((s) => s.actionsFor(reserved.id), 'actions', {StaffAction.admit, StaffAction.voidTicket})
            .having(
              (s) => s.notice,
              'notice',
              isA<StaffActionSucceeded>().having((n) => n.action, 'action', StaffAction.confirmPayment),
            ),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'ignores a second admission while the first is in flight',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(TicketAdmissionRequested(paid.id))
          ..add(TicketAdmissionRequested(paid.id));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>().having((s) => s.inFlightId, 'in flight', paid.id),
        isA<EventTicketsLoaded>().having((s) => s.notice, 'notice', isA<StaffActionSucceeded>()),
      ],
      verify: (_) async =>
          expect((await store.findTicket(paid.id))?.status, Used(scannedAt: now, scannedBy: organizer.id)),
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'stays busy while the cursor moves, so a second admission is still ignored',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(TicketAdmissionRequested(paid.id))
          ..add(const TicketCursorMoved(1))
          ..add(TicketAdmissionRequested(paid.id));
      },
      skip: 2,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.inFlightId, 'in flight', paid.id)
            .having((s) => s.cursor, 'cursor', 0),
        isA<EventTicketsLoaded>()
            .having((s) => s.inFlightId, 'in flight', paid.id)
            .having((s) => s.cursor, 'cursor', 1),
        isA<EventTicketsLoaded>().having((s) => s.isBusy, 'busy', isFalse).having((s) => s.cursor, 'cursor', 1),
      ],
      verify: (_) => expect(store.saves, 1),
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'keeps the filter the user changed while the action was running',
      build: build,
      act: (bloc) async {
        await loaded(bloc, selectedId: reserved.id);
        bloc
          ..add(PaymentConfirmationRequested(reserved.id))
          ..add(const TicketStatusFilterChanged(StatusFilter.paid));
      },
      skip: 4,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.filter, 'filter', StatusFilter.paid)
            .having((s) => s.visible.length, 'visible', 2)
            .having((s) => s.selectedId, 'selected', isNull)
            .having((s) => s.notice, 'notice', isA<StaffActionSucceeded>()),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'a rejected action reloads, so a reservation that ran out meanwhile shows as expired',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        movable.instant = now.add(reservationHold + const Duration(minutes: 1));
        bloc.add(PaymentConfirmationRequested(reserved.id));
      },
      skip: 3,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.notice, 'notice', const StaffActionRejected(ReservationExpired()))
            .having((s) => s.data.tickets.first.status, 'status', isA<Expired>())
            .having((s) => s.actionsFor(reserved.id), 'actions', isEmpty),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'a request for another event during an action wins over the stale result',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc
          ..add(TicketAdmissionRequested(paid.id))
          ..add(const EventTicketsRequested(EventId('e-3')));
        await bloc.stream.firstWhere((s) => s is EventTicketsLoaded && s.data.event.id == const EventId('e-3'));
      },
      verify: (bloc) {
        final state = bloc.state as EventTicketsLoaded;
        expect(state.data.event.id, const EventId('e-3'));
        expect(state.isBusy, isFalse);
      },
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'reports a rejected rule without touching the data',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(TicketAdmissionRequested(used.id));
      },
      skip: 3,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.data.tickets, 'tickets', [reserved, paid, used])
            .having((s) => s.notice, 'notice', const StaffActionRejected(TicketAlreadyUsed())),
      ],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'reports a repository failure and keeps the data on screen',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        store.failingRequests = 1;
        bloc.add(PaymentConfirmationRequested(reserved.id));
      },
      skip: 3,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.data.tickets, 'tickets', [reserved, paid, used])
            .having((s) => s.isBusy, 'busy', isFalse)
            .having((s) => s.notice, 'notice', isA<StaffActionFailed>()),
      ],
    );

    group('voiding', () {
      blocTest<EventTicketsBloc, EventTicketsState>(
        'cancels the ticket with the reason',
        build: build,
        act: (bloc) async {
          await loaded(bloc);
          bloc.add(TicketVoidRequested(paid.id, reason: 'Duplikat.'));
        },
        skip: 3,
        expect: () => [
          isA<EventTicketsLoaded>().having(
            (s) => s.notice,
            'notice',
            isA<StaffActionSucceeded>().having((n) => n.ticket.status, 'status', isA<Cancelled>()),
          ),
        ],
      );
    });

    blocTest<EventTicketsBloc, EventTicketsState>(
      'acknowledging the notice clears it',
      build: build,
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(TicketAdmissionRequested(used.id));
        await bloc.stream.firstWhere((s) => s is EventTicketsLoaded && s.notice != null);
        bloc.add(const EventTicketsNoticeAcknowledged());
      },
      skip: 4,
      expect: () => [isA<EventTicketsLoaded>().having((s) => s.notice, 'notice', isNull)],
    );

    blocTest<EventTicketsBloc, EventTicketsState>(
      'refreshing reloads the data and keeps the filter, the selection and the cursor',
      build: build,
      act: (bloc) async {
        await loaded(bloc, selectedId: paid.id);
        bloc.add(const TicketStatusFilterChanged(StatusFilter.paid));
        await store.saveAll([reserved.copyWith(status: Paid(paidAt: now))]);
        bloc.add(const EventTicketsRefreshed());
      },
      skip: 3,
      expect: () => [
        isA<EventTicketsLoaded>()
            .having((s) => s.visible.length, 'visible', 2)
            .having((s) => s.filter, 'filter', StatusFilter.paid)
            .having((s) => s.selectedId, 'selected', paid.id)
            .having((s) => s.cursor, 'cursor', 0),
      ],
    );
  });
}
