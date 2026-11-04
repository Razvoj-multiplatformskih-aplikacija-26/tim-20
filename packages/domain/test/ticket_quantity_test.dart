import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TicketQuantity.parse', () {
    test('accepts from 1 to 4 tickets', () {
      expect(TicketQuantity.parse(1, alreadyHeld: 0).valueOrNull?.value, 1);
      expect(TicketQuantity.parse(4, alreadyHeld: 0).valueOrNull?.value, 4);
    });

    test('rejects 0 and 5 as an invalid quantity', () {
      expect(TicketQuantity.parse(0, alreadyHeld: 0), const Failure<TicketQuantity>(InvalidTicketQuantity(0)));
      expect(TicketQuantity.parse(5, alreadyHeld: 0), const Failure<TicketQuantity>(InvalidTicketQuantity(5)));
    });

    test('rejects a quantity that would exceed the limit together with held tickets', () {
      expect(
        TicketQuantity.parse(2, alreadyHeld: 3),
        const Failure<TicketQuantity>(TicketLimitExceeded(alreadyHeld: 3, requested: 2)),
      );
    });

    test('accepts a quantity that exactly fills the limit', () {
      expect(TicketQuantity.parse(1, alreadyHeld: 3).valueOrNull?.value, 1);
    });
  });
}
