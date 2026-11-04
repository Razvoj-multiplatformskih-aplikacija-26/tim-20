import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('counts the tickets of an event by their status at now', () {
    final tickets = [
      ticket(status: Reserved(expiresAt: now.add(reservationHold))),
      ticket(status: Paid(paidAt: now)),
      ticket(
        status: Paid(paidAt: now, confirmedBy: organizer.id),
      ),
      ticket(
        status: Used(scannedAt: now, scannedBy: usher.id),
      ),
      ticket(
        status: Cancelled(at: now, by: ana.id),
      ),
      ticket(status: Reserved(expiresAt: now.subtract(const Duration(minutes: 1)))),
    ];

    final summary = summarize(event(capacity: 10), tickets, now: now);

    expect(summary, const TicketSummary(capacity: 10, reserved: 1, paid: 2, used: 1, cancelled: 1, expired: 1));
    expect(summary.sold, 4);
    expect(summary.remaining, 6);
    expect(summary.occupancy, 0.4);
    expect(summary.entered, 1);
  });

  test('an event without seats is never occupied', () {
    final summary = summarize(event(capacity: 0), const [], now: now);
    expect(summary.occupancy, 0);
    expect(summary.remaining, 0);
  });
}
