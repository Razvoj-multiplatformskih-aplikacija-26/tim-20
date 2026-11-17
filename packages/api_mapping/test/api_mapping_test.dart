import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 21, 18);
  const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
  const organizer = User(id: UserId('u-org'), name: 'Jovana Organizator', role: Role.organizer);
  final statuses = <TicketStatus>[
    Reserved(expiresAt: at),
    Paid(paidAt: at),
    Paid(paidAt: at, confirmedBy: organizer.id),
    Used(scannedAt: at, scannedBy: organizer.id),
    Cancelled(at: at, by: ana.id, reason: 'Ne mogu da dođem.'),
    Expired(at: at),
  ];

  test('every status goes to the wire and back unchanged', () {
    for (final status in statuses) {
      expect(status.toDto().toDomain(), status, reason: '$status');
    }
  });

  test('an event and a ticket go to the wire and back unchanged', () {
    final event = Event(
      id: const EventId('e-1'),
      name: 'Žurka dobrodošlice',
      venue: 'Dom omladine',
      startsAt: at,
      priceRsd: 800,
      capacity: 50,
      organizerId: organizer.id,
    );
    final ticket = Ticket(
      id: const TicketId('t-01'),
      eventId: event.id,
      holderId: ana.id,
      holderName: ana.name,
      status: statuses.first,
      createdAt: at,
      code: 'T20-t-01',
    );
    expect(event.toDto().toDomain(), event);
    expect(event.toDto().price.toJson(), {'amount': 800, 'currency': 'RSD'});
    expect(ticket.toDto().toDomain(), ticket);
    expect(ana.toDto().toDomain(), ana);
  });

  test('every domain error reaches the client as the same error, with the data of the rule', () {
    final errors = <DomainError>[
      const InvalidTicketQuantity(5, min: 1, max: 4),
      const TicketLimitExceeded(alreadyHeld: 3, requested: 2, max: 4),
      const NotEnoughSeats(0),
      const EventAlreadyStarted(),
      const CancellationTooLate(notice: Duration(hours: 24)),
      const ReservationExpired(),
      const TicketAlreadyUsed(),
      InvalidTransition(
        from: Paid(paidAt: at),
        to: Paid(paidAt: at),
      ),
      const NotAllowed(),
      const NotFound(),
    ];
    for (final error in errors) {
      final problem = ProblemDto.fromJson(error.toProblem().toJson());
      expect(problem.toDomainError(), error, reason: '$error');
    }
  });

  test('the statuses follow the table: 422 broken rule, 409 conflict, 403 not allowed, 404 missing', () {
    expect(const InvalidTicketQuantity(5, min: 1, max: 4).toProblem().status, 422);
    expect(const NotEnoughSeats(0).toProblem().status, 409);
    expect(const TicketLimitExceeded(alreadyHeld: 3, requested: 2, max: 4).toProblem().status, 409);
    expect(const CancellationTooLate(notice: Duration(hours: 24)).toProblem().min, 1440);
    expect(const NotAllowed().toProblem().status, 403);
    expect(const NotFound().toProblem().status, 404);
  });

  test('a code from a newer server is not a domain error the client knows', () {
    expect(const ProblemDto(status: 409, code: 'seat-on-fire', title: '').toDomainError(), isNull);
    expect(const ProblemDto(status: 409, code: ErrorCodes.notEnoughSeats, title: '').toDomainError(), isNull);
  });

  test('a status, a role or a currency the client does not know is refused as a format error', () {
    expect(() => const TicketStatusDto(kind: 'refunded').toDomain(), throwsFormatException);
    expect(() => const TicketStatusDto(kind: TicketStatusDto.used).toDomain(), throwsFormatException);
    expect(() => const UserDto(id: 'u-x', name: 'X', role: 'admin').toDomain(), throwsFormatException);
    final euro = EventDto(
      id: 'e-1',
      name: 'Koncert',
      venue: 'SKC',
      startsAt: at,
      price: const MoneyDto(amount: 10, currency: 'EUR'),
      capacity: 10,
      organizerId: 'u-org',
    );
    expect(euro.toDomain, throwsFormatException);
  });
}
