import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final t = DateTime.utc(2026, 11, 1);

  test('every filter keeps only its status, and all keeps everything', () {
    final statuses = <TicketStatus>[
      Reserved(expiresAt: t),
      Paid(paidAt: t),
      Used(scannedAt: t, scannedBy: const UserId('u-org')),
      Cancelled(at: t, by: const UserId('u-ana')),
      Expired(at: t),
    ];
    expect(statuses.where(StatusFilter.all.matches), hasLength(5));
    expect(statuses.where(StatusFilter.reserved.matches).single, isA<Reserved>());
    expect(statuses.where(StatusFilter.paid.matches).single, isA<Paid>());
    expect(statuses.where(StatusFilter.used.matches).single, isA<Used>());
    expect(statuses.where(StatusFilter.cancelled.matches).single, isA<Cancelled>());
    expect(statuses.where(StatusFilter.expired.matches).single, isA<Expired>());
  });
}
