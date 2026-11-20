import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/testing.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final t = DateTime.utc(2026, 11, 4, 12);
  const u = UserId('u-org');
  final statuses = <TicketStatus>[
    Reserved(expiresAt: t),
    Paid(paidAt: t),
    Used(scannedAt: t, scannedBy: u),
    Cancelled(at: t, by: u),
    Expired(at: t),
  ];

  test('every domain error has a Serbian message', () {
    final errors = <DomainError>[
      const InvalidTicketQuantity(0, min: 1, max: 4),
      const TicketLimitExceeded(alreadyHeld: 3, requested: 2, max: 4),
      const NotEnoughSeats(0),
      const EventAlreadyStarted(),
      const CancellationTooLate(notice: Duration(hours: 24)),
      const ReservationExpired(),
      const TicketAlreadyUsed(),
      InvalidTransition(from: statuses[1], to: statuses[1]),
      const NotAllowed(),
      const NotFound(),
    ];
    for (final error in errors) {
      expect(error.message, isNotEmpty, reason: '$error');
    }
    expect(const TicketLimitExceeded(alreadyHeld: 3, requested: 2, max: 4).message, contains('3'));
  });

  test('messages show the limits the rule reported, so a newer server explains its own limits', () {
    expect(const TicketLimitExceeded(alreadyHeld: 1, requested: 2, max: 2).message, contains('najviše 2 karte'));
    expect(const InvalidTicketQuantity(3, min: 1, max: 2).message, 'Broj karata je od 1 do 2.');
    expect(const CancellationTooLate(notice: Duration(hours: 48)).message, contains('48 sata'));
  });

  group('TicketsTheme', () {
    test('uses Inter from this package', () {
      expect(TicketsTheme.light().textTheme.bodyMedium?.fontFamily, 'packages/ui/Inter');
      expect(TicketsTheme.dark().textTheme.bodyMedium?.fontFamily, 'packages/ui/Inter');
    });

    test('gives every status its own color in both schemes', () {
      for (final theme in [TicketsTheme.light(), TicketsTheme.dark()]) {
        final colors = theme.statusColors;
        final backgrounds = {for (final status in statuses) colors.of(status).$1};
        expect(backgrounds, hasLength(statuses.length), reason: '${theme.brightness}');
      }
    });
  });

  group('StatusBadge', () {
    testWidgets('shows the label and is announced as a status', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: TicketsTheme.light(), home: StatusBadge(statuses[1])));
      expect(find.text('Plaćena'), findsOneWidget);
      expect(find.bySemanticsLabel('Stanje: Plaćena'), findsOneWidget);
    });
  });

  group('failureMessage', () {
    test('explains every kind of failure without technical text', () {
      const messages = {
        RepositoryFailure.unavailable: 'Podaci trenutno nisu dostupni.',
        RepositoryFailure.unreachable: serverUnreachableMessage,
        RepositoryFailure.serverError: 'Greška na serveru.',
        RepositoryFailure.refused: 'Server nije prihvatio zahtev.',
        RepositoryFailure.sessionExpired: sessionExpiredMessage,
      };
      for (final MapEntry(key: failure, value: message) in messages.entries) {
        expect(failureMessage(RepositoryException('x', failure: failure)), message);
      }
      expect(failureMessage(StateError('x')), 'Podaci trenutno nisu dostupni.');
      expect(failureMessage(null), 'Podaci trenutno nisu dostupni.');
    });
  });

  group('FailureView', () {
    testWidgets('says the server is unreachable and offers a retry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TicketsTheme.light(),
          home: FailureView(
            onRetry: () {},
            cause: const RepositoryException('x', failure: RepositoryFailure.unreachable),
          ),
        ),
      );
      expect(find.text('Nema veze sa serverom.'), findsOneWidget);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });

    testWidgets('calls onRetry on Pokušaj ponovo', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: TicketsTheme.light(),
          home: FailureView(onRetry: () => retried++),
        ),
      );
      await tester.tap(find.text('Pokušaj ponovo'));
      expect(retried, 1);
    });
  });

  group('LoginScreen', () {
    const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);

    Widget screen({SignOutReason? reason, void Function(User)? onSignedIn, bool signedIn = false}) => MaterialApp(
      theme: TicketsTheme.light(),
      home: LoginScreen(
        title: 'Ulaznice',
        logIn: LogIn(sessions: InMemorySessions(ana, signedIn: signedIn)),
        onSignedIn: onSignedIn ?? (_) {},
        roleNotAllowedMessage: 'Aplikacija je za posetioce.',
        reason: reason,
      ),
    );

    testWidgets('explains an expired session above the form', (tester) async {
      await tester.pumpWidget(screen(reason: SignOutReason.expired));
      expect(find.text(sessionExpiredMessage), findsOneWidget);
      expect(find.text('Korisničko ime'), findsOneWidget);
      expect(find.text('Lozinka'), findsOneWidget);
    });

    testWidgets('explains a role the app does not admit with the message of the app', (tester) async {
      await tester.pumpWidget(screen(reason: SignOutReason.roleNotAllowed));
      expect(find.text('Aplikacija je za posetioce.'), findsOneWidget);
    });

    testWidgets('a wrong password is explained and a right one hands over the user', (tester) async {
      User? signedIn;
      await tester.pumpWidget(screen(onSignedIn: (user) => signedIn = user));
      await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), 'ana');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();
      expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
      expect(signedIn, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'tim20-demo');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();
      expect(signedIn, ana);
    });
  });
}
