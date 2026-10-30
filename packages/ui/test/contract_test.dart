import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('prices are written in dinars with a dot between thousands', () {
    expect(formatRsd(1200), '1.200 RSD');
    expect(formatRsd(500), '500 RSD');
  });

  test('messages take the numbers from the rules', () {
    expect(const TicketLimitExceeded(alreadyHeld: 3, requested: 2).message, contains('najviše $maxTicketsPerEvent'));
    expect(const CancellationTooLate().message, contains('${cancellationNotice.inHours} sata'));
  });

  test('every status has a Serbian label', () {
    expect(Expired(at: DateTime.utc(2026)).label, 'Istekla');
  });
}
