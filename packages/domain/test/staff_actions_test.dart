import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final reserved = ticket(status: Reserved(expiresAt: now.add(reservationHold)));
  final paid = ticket(status: Paid(paidAt: now));
  final used = ticket(
    status: Used(scannedAt: now, scannedBy: usher.id),
  );
  final cancelled = ticket(
    status: Cancelled(at: now, by: ana.id),
  );
  final expired = ticket(status: Reserved(expiresAt: now.subtract(const Duration(minutes: 1))));

  group('confirmPayment', () {
    test('marks a reserved ticket paid by the organizer', () {
      final result = confirmPayment(reserved, by: organizer, now: now);
      expect(result.valueOrNull?.status, Paid(paidAt: now, confirmedBy: organizer.id));
    });

    test('rejects a visitor and an usher', () {
      expect(confirmPayment(reserved, by: ana, now: now), const Failure<Ticket>(NotAllowed()));
      expect(confirmPayment(reserved, by: usher, now: now), const Failure<Ticket>(NotAllowed()));
    });

    test('rejects a reservation whose time ran out', () {
      expect(confirmPayment(expired, by: organizer, now: now), const Failure<Ticket>(ReservationExpired()));
    });

    test('rejects a paid ticket', () {
      expect(
        confirmPayment(paid, by: organizer, now: now),
        Failure<Ticket>(
          InvalidTransition(
            from: paid.status,
            to: Paid(paidAt: now),
          ),
        ),
      );
    });
  });

  group('admitTicket', () {
    test('marks a paid ticket used by the organizer or an usher', () {
      expect(
        admitTicket(paid, by: organizer, now: now).valueOrNull?.status,
        Used(scannedAt: now, scannedBy: organizer.id),
      );
      expect(admitTicket(paid, by: usher, now: now).valueOrNull?.status, Used(scannedAt: now, scannedBy: usher.id));
    });

    test('rejects a visitor', () {
      expect(admitTicket(paid, by: ana, now: now), const Failure<Ticket>(NotAllowed()));
    });

    test('lets a ticket in only once', () {
      expect(admitTicket(used, by: usher, now: now), const Failure<Ticket>(TicketAlreadyUsed()));
    });

    test('rejects a ticket that is not paid', () {
      expect(
        admitTicket(reserved, by: usher, now: now),
        Failure<Ticket>(
          InvalidTransition(
            from: reserved.status,
            to: Used(scannedAt: now, scannedBy: usher.id),
          ),
        ),
      );
    });
  });

  group('staffActionsFor', () {
    final concert = event();

    test('offers what the organizer may do in every status', () {
      Set<StaffAction> actions(Ticket t) => staffActionsFor(t, concert, by: organizer, now: now);
      expect(actions(reserved), {StaffAction.confirmPayment, StaffAction.voidTicket});
      expect(actions(paid), {StaffAction.admit, StaffAction.voidTicket});
      expect(actions(used), isEmpty);
      expect(actions(cancelled), isEmpty);
      expect(actions(expired), isEmpty);
    });

    test('lets an usher only admit', () {
      expect(staffActionsFor(paid, concert, by: usher, now: now), {StaffAction.admit});
      expect(staffActionsFor(reserved, concert, by: usher, now: now), isEmpty);
    });

    test('offers nothing to a visitor, not even on their own ticket', () {
      expect(staffActionsFor(reserved, concert, by: ana, now: now), isEmpty);
      expect(staffActionsFor(paid, concert, by: ana, now: now), isEmpty);
    });

    test('no longer offers voiding once the event has started', () {
      final started = event(startsAt: now);
      expect(staffActionsFor(paid, started, by: organizer, now: now), {StaffAction.admit});
    });
  });
}
