import 'dart:async';

import 'package:backoffice/data/fake_box_office.dart';
import 'package:backoffice/data/seed.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/widgets/ticket_detail_panel.dart';
import 'package:backoffice/widgets/ticket_table.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

final class _ExpiringSessions implements SessionRepository {
  _ExpiringSessions({this.restoreFails = false});

  final bool restoreFails;
  final _expirations = StreamController<void>.broadcast();

  void expire() => _expirations.add(null);

  @override
  Future<User?> logIn({required String username, required String password}) async => organizer;

  @override
  Future<User?> current() async {
    if (restoreFails) {
      throw const RepositoryException('Session expired', failure: RepositoryFailure.sessionExpired);
    }
    return organizer;
  }

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => _expirations.stream;
}

/// Delegates to the fake box office, except that saving a ticket runs [onSave] instead.
final class _TicketsWithSave implements TicketRepository {
  _TicketsWithSave(this._inner, this.onSave);

  final FakeBoxOffice _inner;
  final Future<Result<Ticket>> Function(Ticket ticket, TicketStatus from) onSave;

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) => _inner.ticketsOf(holderId);

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) => _inner.ticketsFor(eventId);

  @override
  Future<Ticket?> findTicket(TicketId id) => _inner.findTicket(id);

  @override
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  }) => _inner.reserve(eventId: eventId, by: by, quantity: quantity, now: now);

  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) => onSave(ticket, from);
}

BackofficeDependencies dependenciesWith({
  SessionRepository? sessions,
  Future<Result<Ticket>> Function(FakeBoxOffice fake, Ticket ticket, TicketStatus from)? onSave,
}) {
  final clock = FixedClock(sundayEvening);
  final fake = FakeBoxOffice(clock: clock, latency: Duration.zero);
  return BackofficeDependencies(
    clock: clock,
    events: fake,
    tickets: onSave == null ? fake : _TicketsWithSave(fake, (ticket, from) => onSave(fake, ticket, from)),
    sessions: sessions ?? InMemorySessions(organizer),
    fake: fake,
  );
}

void main() {
  Finder inPanel(String text) => find.descendant(of: find.byType(TicketDetailPanel), matching: find.text(text));
  Finder inTable(String text) => find.descendant(of: find.byType(TicketTable), matching: find.text(text));

  Future<void> signIn(WidgetTester tester, String username) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'lozinka');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
  }

  Future<void> openTicket(WidgetTester tester, String code, {BackofficeDependencies? dependencies}) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, dependencies: dependencies, location: '/dogadjaji/e-a');
    await settle(tester);
    await tester.tap(inTable(code));
    await settle(tester);
  }

  testWidgets('signed out shows the login screen', (tester) async {
    await pumpBackoffice(tester, dependencies: fakeDependencies(signedIn: false));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Ulaznice · backoffice'), findsOneWidget);
  });

  testWidgets("a visitor is refused with 'Backoffice je za organizatore i redare.'", (tester) async {
    await pumpBackoffice(tester, dependencies: fakeDependencies(signedIn: false, staff: ana));
    await settle(tester);

    await signIn(tester, 'ana');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Backoffice je za organizatore i redare.'), findsOneWidget);
  });

  testWidgets("signed in shows the organizer's events and the name in the header", (tester) async {
    await pumpBackoffice(tester, dependencies: fakeDependencies(signedIn: false));
    await settle(tester);

    await signIn(tester, 'organizator');

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Brucošijada'), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Organizator')), findsOneWidget);
  });

  testWidgets('logging out returns to the login screen', (tester) async {
    await pumpBackoffice(tester);
    await settle(tester);
    expect(find.text('Brucošijada'), findsOneWidget);

    await tester.tap(find.byTooltip('Odjavi se'));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Brucošijada'), findsNothing);
  });

  testWidgets("an expired session shows the login screen with 'Prijava je istekla. Prijavite se ponovo.'", (
    tester,
  ) async {
    final sessions = _ExpiringSessions();
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(
      tester,
      dependencies: dependenciesWith(sessions: sessions),
      location: '/dogadjaji/e-a',
    );
    await settle(tester);
    expect(find.byType(TicketTable), findsOneWidget);

    sessions.expire();
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
  });

  testWidgets('a restored session that expired shows the login screen with the expiry message', (tester) async {
    await pumpBackoffice(tester, dependencies: dependenciesWith(sessions: _ExpiringSessions(restoreFails: true)));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
  });

  testWidgets('a refresh in the browser keeps the address after the session is restored', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a?selected=t-01');
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    await settle(tester);

    expect(currentLocation(tester), '/dogadjaji/e-a?selected=t-01');
    expect(find.descendant(of: find.byType(TicketDetailPanel), matching: find.text('T20-t-01')), findsOneWidget);
  });

  testWidgets('the next user after a logout starts from the event list', (tester) async {
    useWindow(tester, width: 1200, height: 800);
    await pumpBackoffice(tester, location: '/dogadjaji/e-a');
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.byTooltip('Odjavi se'));
    await settle(tester);

    await signIn(tester, 'organizator');

    expect(currentLocation(tester), '/');
  });

  testWidgets("the server down shows 'Nema veze sa serverom.' and 'Pokušaj ponovo'", (tester) async {
    final dependencies = fakeDependencies()..fake!.failingRequests = 1;
    await pumpBackoffice(tester, dependencies: dependencies);
    await settle(tester);

    expect(find.text('Nema veze sa serverom.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.text('Brucošijada'), findsOneWidget);
  });

  testWidgets('the usher can only admit a paid ticket', (tester) async {
    await openTicket(tester, 'T20-t-01', dependencies: fakeDependencies(staff: usher));
    expect(inPanel('Rezervisana'), findsOneWidget);
    expect(inPanel('Potvrdi plaćanje'), findsNothing);
    expect(inPanel('Poništi'), findsNothing);

    await tester.tap(inTable('T20-t-07'));
    await settle(tester);
    expect(inPanel('Pusti na ulaz'), findsOneWidget);
    expect(inPanel('Potvrdi plaćanje'), findsNothing);
    expect(inPanel('Poništi'), findsNothing);
  });

  testWidgets(
    "an action refused by a newer server shows 'Server nije prihvatio zahtev.' and an unreachable server 'Nema veze sa serverom.'",
    (tester) async {
      var failure = RepositoryFailure.refused;
      final dependencies = dependenciesWith(
        onSave: (_, _, _) async => throw RepositoryException('Refused', failure: failure),
      );
      await openTicket(tester, 'T20-t-07', dependencies: dependencies);

      await tester.tap(inPanel('Pusti na ulaz'));
      await settle(tester);
      expect(find.text('Server nije prihvatio zahtev.'), findsOneWidget);

      failure = RepositoryFailure.unreachable;
      ScaffoldMessenger.of(tester.element(find.byType(TicketTable))).removeCurrentSnackBar();
      await tester.tap(inPanel('Pusti na ulaz'));
      await settle(tester);
      expect(find.text('Nema veze sa serverom.'), findsOneWidget);
    },
  );

  testWidgets('a rejected action shows the reason and the reloaded table', (tester) async {
    final dependencies = dependenciesWith(
      onSave: (fake, ticket, from) async {
        await fake.save(ticket, from: from);
        return fake.save(ticket, from: from);
      },
    );
    await openTicket(tester, 'T20-t-07', dependencies: dependencies);
    expect(inPanel('Plaćena'), findsOneWidget);

    await tester.tap(inPanel('Pusti na ulaz'));
    await settle(tester);

    expect(find.text('Karta je već iskorišćena.'), findsOneWidget);
    expect(inPanel('Iskorišćena'), findsOneWidget);
    expect(inPanel('Pusti na ulaz'), findsNothing);
  });
}
