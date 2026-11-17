import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  final ticketJson = {
    'id': 't-01',
    'eventId': 'e-1',
    'holderId': 'u-ana',
    'holderName': 'Ana Anić',
    'status': {'kind': 'reserved', 'expiresAt': '2026-11-21T18:15:00.000Z'},
    'createdAt': '2026-11-21T18:00:00.000Z',
    'code': 'T20-t-01',
  };

  test('a ticket goes to JSON and back unchanged', () {
    expect(TicketDto.fromJson(ticketJson).toJson(), ticketJson);
  });

  test('an event goes to JSON and back with its price as whole dinars and a currency', () {
    final json = {
      'id': 'e-1',
      'name': 'Žurka dobrodošlice',
      'venue': 'Dom omladine',
      'startsAt': '2026-11-24T19:00:00.000Z',
      'price': {'amount': 800, 'currency': 'RSD'},
      'capacity': 50,
      'organizerId': 'u-org',
    };
    expect(EventDto.fromJson(json).toJson(), json);
  });

  test('an older client reads a ticket that carries a field it does not know yet', () {
    final ticket = TicketDto.fromJson({...ticketJson, 'seat': 'A1'});
    expect(ticket.id, 't-01');
    expect(ticket.status.kind, TicketStatusDto.reserved);
  });

  test('a time without a zone is refused', () {
    expect(() => TicketDto.fromJson({...ticketJson, 'createdAt': '2026-11-21T18:00:00'}), throwsFormatException);
    expect(() => TicketDto.fromJson({...ticketJson}..remove('code')), throwsFormatException);
  });

  test('a problem names its type and code and leaves out the data it does not have', () {
    const problem = ProblemDto(status: 409, code: ErrorCodes.notEnoughSeats, title: 'Not enough seats', value: 0);
    expect(problem.toJson(), {
      'type': 'tag:raf.rs,2026:tim-20/problem/not-enough-seats',
      'title': 'Not enough seats',
      'status': 409,
      'code': 'not-enough-seats',
      'value': 0,
    });
    expect(ProblemDto.fromJson(problem.toJson()).toJson(), problem.toJson());
  });

  test('a session carries the token only when the client does not keep it in a cookie', () {
    final session = SessionDto(
      user: const UserDto(id: 'u-ana', name: 'Ana Anić', role: 'visitor'),
      expiresAt: DateTime.utc(2026, 11, 21, 23),
    );
    expect(session.toJson().containsKey('token'), isFalse);
    expect(SessionDto.fromJson(session.toJson()).user.role, 'visitor');
    expect(LoginDto.fromJson(const LoginDto(username: 'ana', password: 'x', cookie: true).toJson()).cookie, isTrue);
  });
}
