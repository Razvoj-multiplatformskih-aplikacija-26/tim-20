import 'package:domain/domain.dart';

const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
const marko = User(id: UserId('u-marko'), name: 'Marko Marković', role: Role.visitor);
const _organizer = UserId('u-org');
const _usher = UserId('u-usher');

/// Events around [now]: one already over, one tonight (so cancellation is too late), the rest later.
List<Event> seedEvents(DateTime now) {
  Event event(
    String id,
    String name,
    String venue, {
    required Duration startsIn,
    required int price,
    required int capacity,
  }) => Event(
    id: EventId(id),
    name: name,
    venue: venue,
    startsAt: now.add(startsIn),
    priceRsd: price,
    capacity: capacity,
    organizerId: _organizer,
  );

  return [
    event('e-1', 'Brucošijada 2026', 'Dom omladine', startsIn: const Duration(days: 10), price: 900, capacity: 120),
    event('e-2', 'Hakaton: 24 sata koda', 'RAF, sala 7', startsIn: const Duration(hours: 20), price: 300, capacity: 60),
    event('e-3', 'Stand-up veče', 'Klub Fest', startsIn: const Duration(days: 3, hours: 7), price: 700, capacity: 12),
    event(
      'e-4',
      'Filmsko veče: Matrix',
      'RAF, amfiteatar',
      startsIn: const Duration(days: -2, hours: -5),
      price: 200,
      capacity: 80,
    ),
    event(
      'e-5',
      'Turnir u stonom tenisu',
      'SC Vračar',
      startsIn: const Duration(days: 5, hours: -2),
      price: 400,
      capacity: 32,
    ),
    event(
      'e-6',
      'Žurka kraja semestra',
      'Splav Sloboda',
      startsIn: const Duration(days: 14, hours: 9),
      price: 1200,
      capacity: 200,
    ),
    event(
      'e-7',
      'Radionica: Flutter za početnike',
      'RAF, sala 3',
      startsIn: const Duration(days: 1, hours: 6),
      price: 0,
      capacity: 25,
    ),
  ];
}

/// Ana's tickets cover every status, including a reservation about to expire and one that already has.
List<Ticket> seedTickets(DateTime now) {
  var next = 1;
  Ticket ticket(
    String id,
    String eventId,
    TicketStatus status, {
    User holder = ana,
    Duration age = const Duration(days: 1),
  }) => Ticket(
    id: TicketId(id),
    eventId: EventId(eventId),
    holderId: holder.id,
    holderName: holder.name,
    status: status,
    createdAt: now.subtract(age),
    code: 'ULZ-$id',
  );

  Ticket other(String eventId) => ticket(
    'o-${next++}',
    eventId,
    Paid(paidAt: now.subtract(const Duration(days: 2))),
    holder: marko,
    age: const Duration(days: 3),
  );

  final filmNight = now.subtract(const Duration(days: 2, hours: 5));
  return [
    ticket('a-1', 'e-1', Paid(paidAt: now.subtract(const Duration(days: 1)))),
    ticket('a-2', 'e-5', Reserved(expiresAt: now.add(const Duration(minutes: 5))), age: const Duration(minutes: 10)),
    ticket(
      'a-3',
      'e-6',
      Reserved(expiresAt: now.subtract(const Duration(minutes: 10))),
      age: const Duration(minutes: 25),
    ),
    ticket('a-4', 'e-1', Expired(at: now.subtract(const Duration(days: 2))), age: const Duration(days: 2, minutes: 15)),
    ticket('a-5', 'e-2', Paid(paidAt: now.subtract(const Duration(days: 3)))),
    ticket(
      'a-6',
      'e-4',
      Used(scannedAt: filmNight.add(const Duration(minutes: 12)), scannedBy: _usher),
      age: const Duration(days: 6),
    ),
    ticket(
      'a-7',
      'e-4',
      Used(scannedAt: filmNight.add(const Duration(minutes: 13)), scannedBy: _usher),
      age: const Duration(days: 6),
    ),
    ticket(
      'a-8',
      'e-5',
      Cancelled(at: now.subtract(const Duration(days: 1)), by: ana.id, reason: 'Promena plana.'),
      age: const Duration(days: 4),
    ),
    ticket('a-9', 'e-3', Paid(paidAt: now.subtract(const Duration(days: 4)))),
    ticket('a-10', 'e-6', Paid(paidAt: now.subtract(const Duration(hours: 5)))),
    ticket('a-11', 'e-1', Reserved(expiresAt: now.add(const Duration(minutes: 12))), age: const Duration(minutes: 3)),
    ticket('a-12', 'e-7', Paid(paidAt: now.subtract(const Duration(hours: 30)))),
    // Other visitors, so that the stand-up night has a single seat left.
    for (var i = 0; i < 10; i++) other('e-3'),
    for (var i = 0; i < 25; i++) other('e-1'),
    for (var i = 0; i < 40; i++) other('e-2'),
    for (var i = 0; i < 8; i++) other('e-7'),
  ];
}
