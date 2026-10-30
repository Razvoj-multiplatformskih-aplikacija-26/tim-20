import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_ticketing.dart';

void main() {
  final nextWeek = event('e-1', startsIn: const Duration(days: 7));
  const eventId = EventId('e-1');

  var ids = 0;
  TicketId newId() => TicketId('n-${++ids}');

  PurchaseBloc build(FakeTicketing store) => PurchaseBloc(
    getPurchaseContext: GetPurchaseContext(events: store, tickets: store, clock: clock),
    reserveTickets: ReserveTickets(events: store, tickets: store, clock: clock, newId: newId),
    visitor: ana,
  );

  /// The form is used only once it is on screen, so the tests wait for it like a visitor would.
  Future<void> start(PurchaseBloc bloc) async {
    bloc.add(const PurchaseStarted(eventId));
    await bloc.stream.firstWhere((s) => s is PurchaseReady);
  }

  List<Ticket> held(int count) => [for (var i = 0; i < count; i++) ticket('h-$i', status: Paid(paidAt: now))];

  blocTest<PurchaseBloc, PurchaseState>(
    'started loads the purchase context with one ticket selected',
    build: () => build(FakeTicketing(events: [nextWeek])),
    act: (bloc) => bloc.add(const PurchaseStarted(eventId)),
    expect: () => [
      const PurchaseLoading(),
      PurchaseReady(context: PurchaseContext(event: nextWeek, remaining: 10, alreadyHeld: 0)),
    ],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'an unknown event is not found',
    build: () => build(FakeTicketing()),
    act: (bloc) => bloc.add(const PurchaseStarted(EventId('nope'))),
    expect: () => [const PurchaseLoading(), const PurchaseNotFound()],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'an outage while loading is a failure',
    build: () => build(FakeTicketing(events: [nextWeek])..failingRequests = 1),
    act: (bloc) => bloc.add(const PurchaseStarted(eventId)),
    expect: () => [
      const PurchaseLoading(),
      isA<PurchaseFailure>().having((s) => s.cause, 'cause', isA<RepositoryException>()),
    ],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'five tickets fail the quantity rule',
    build: () => build(FakeTicketing(events: [nextWeek])),
    act: (bloc) async {
      await start(bloc);
      bloc.add(const PurchaseQuantityChanged(5));
    },
    skip: 2,
    expect: () => [
      isA<PurchaseReady>()
          .having((s) => s.quantity, 'quantity', 5)
          .having((s) => s.validation, 'validation', const InvalidTicketQuantity(5)),
    ],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'with three tickets held, two more exceed the limit',
    build: () => build(FakeTicketing(events: [nextWeek], tickets: held(3))),
    act: (bloc) async {
      await start(bloc);
      bloc.add(const PurchaseQuantityChanged(2));
    },
    skip: 2,
    expect: () => [
      isA<PurchaseReady>().having(
        (s) => s.validation,
        'validation',
        const TicketLimitExceeded(alreadyHeld: 3, requested: 2),
      ),
    ],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'submitting a valid quantity reserves the tickets',
    build: () => build(FakeTicketing(events: [nextWeek])),
    act: (bloc) async {
      await start(bloc);
      bloc
        ..add(const PurchaseQuantityChanged(2))
        ..add(const PurchaseSubmitted());
    },
    skip: 3,
    expect: () => [
      isA<PurchaseReady>().having((s) => s.submitting, 'submitting', isTrue),
      isA<PurchaseCompleted>().having((s) => s.tickets, 'tickets', hasLength(2)),
    ],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'submitting with a validation error does nothing',
    build: () => build(FakeTicketing(events: [nextWeek])),
    act: (bloc) async {
      await start(bloc);
      bloc
        ..add(const PurchaseQuantityChanged(0))
        ..add(const PurchaseSubmitted());
    },
    skip: 3,
    expect: () => <PurchaseState>[],
  );

  blocTest<PurchaseBloc, PurchaseState>(
    'seats taken in the meantime are reported as a rejection and the form stays',
    build: () => build(FakeTicketing(events: [event('e-1', startsIn: const Duration(days: 7), capacity: 2)])),
    act: (bloc) async {
      await start(bloc);
      final store = bloc.reserveTickets.tickets;
      await store.saveAll([
        ticket(
          'm-1',
          status: Paid(paidAt: now),
          holder: marko,
        ),
      ]);
      bloc
        ..add(const PurchaseQuantityChanged(2))
        ..add(const PurchaseSubmitted());
    },
    skip: 3,
    expect: () => [
      isA<PurchaseReady>().having((s) => s.submitting, 'submitting', isTrue),
      isA<PurchaseReady>()
          .having((s) => s.submitting, 'submitting', isFalse)
          .having((s) => s.rejection, 'rejection', const NotEnoughSeats(1)),
    ],
  );
}
