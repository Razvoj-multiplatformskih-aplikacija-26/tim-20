import 'package:domain/domain.dart';

const organizer = User(id: UserId('u-org'), name: 'Organizator', role: Role.organizer);
const _usher = UserId('u-usher');

const _visitors = [
  ('u-ana', 'Ana Anić'),
  ('u-marko', 'Marko Marković'),
  ('u-jelena', 'Jelena Jovanović'),
  ('u-nikola', 'Nikola Nikolić'),
  ('u-milica', 'Milica Milić'),
  ('u-stefan', 'Stefan Stefanović'),
  ('u-tamara', 'Tamara Tomić'),
  ('u-luka', 'Luka Lukić'),
  ('u-sara', 'Sara Simić'),
  ('u-petar', 'Petar Petrović'),
];

const brucosijada = EventId('e-a');
const standUp = EventId('e-b');
const radionica = EventId('e-c');

/// Three events, relative to [now]: a big one with tickets in every status, one without tickets and a sold out one.
List<Event> seedEvents(DateTime now) => [
  Event(
    id: brucosijada,
    name: 'Brucošijada',
    venue: 'Dom omladine',
    startsAt: now.add(const Duration(days: 5, hours: 2)),
    priceRsd: 800,
    capacity: 50,
    organizerId: organizer.id,
  ),
  Event(
    id: standUp,
    name: 'Stand-up veče',
    venue: 'Klub studenata tehnike',
    startsAt: now.add(const Duration(days: 12, hours: 3)),
    priceRsd: 500,
    capacity: 20,
    organizerId: organizer.id,
  ),
  Event(
    id: radionica,
    name: 'Radionica 3D štampe',
    venue: 'RAF, učionica 12',
    startsAt: now.add(const Duration(days: 2)),
    priceRsd: 0,
    capacity: 5,
    organizerId: organizer.id,
  ),
];

List<Ticket> seedTickets(DateTime now) {
  var next = 0;
  Ticket ticket(EventId event, TicketStatus status, {Duration bought = const Duration(days: 1)}) {
    final index = next++;
    final (holderId, holderName) = _visitors[index % _visitors.length];
    final id = 't-${(index + 1).toString().padLeft(2, '0')}';
    return Ticket(
      id: TicketId(id),
      eventId: event,
      holderId: UserId(holderId),
      holderName: holderName,
      status: status,
      createdAt: now.subtract(bought),
      code: 'T20-$id',
    );
  }

  final yesterday = now.subtract(const Duration(days: 1));
  return [
    // Brucošijada: 6 reserved (3 about to run out), 20 paid, 8 used, 3 cancelled, 3 expired.
    for (final minutes in [2, 5, 9, 14, 14, 15])
      ticket(
        brucosijada,
        Reserved(expiresAt: now.add(Duration(minutes: minutes))),
        bought: Duration(minutes: 15 - minutes),
      ),
    for (var i = 0; i < 20; i++)
      ticket(brucosijada, Paid(paidAt: yesterday, confirmedBy: i % 4 == 0 ? organizer.id : null)),
    for (var i = 0; i < 8; i++)
      ticket(
        brucosijada,
        Used(
          scannedAt: now.subtract(Duration(minutes: 30 - i)),
          scannedBy: _usher,
        ),
      ),
    for (var i = 0; i < 3; i++)
      ticket(
        brucosijada,
        Cancelled(at: yesterday, by: UserId(_visitors[i].$1), reason: i == 0 ? 'Promena plana.' : ''),
      ),
    for (var i = 0; i < 3; i++) ticket(brucosijada, Expired(at: yesterday)),
    // Radionica: sold out.
    for (var i = 0; i < 5; i++) ticket(radionica, Paid(paidAt: yesterday)),
  ];
}
