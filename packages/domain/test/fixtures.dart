import 'package:domain/domain.dart';

/// Shared examples for the domain tests. Every rule receives [now] explicitly.
final now = DateTime.utc(2026, 11, 4, 12);

const organizer = User(id: UserId('u-org'), name: 'Organizator', role: Role.organizer);
const usher = User(id: UserId('u-usher'), name: 'Redar', role: Role.usher);
const ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
const marko = User(id: UserId('u-marko'), name: 'Marko Marković', role: Role.visitor);

Event event({DateTime? startsAt, int capacity = 50, EventId id = const EventId('e-1')}) => Event(
  id: id,
  name: 'Brucošijada',
  venue: 'Dom omladine',
  startsAt: startsAt ?? now.add(const Duration(days: 7)),
  priceRsd: 1200,
  capacity: capacity,
  organizerId: organizer.id,
);

int _nextTicket = 0;

Ticket ticket({required TicketStatus status, User holder = ana, EventId eventId = const EventId('e-1')}) {
  final id = TicketId('t-${++_nextTicket}');
  return Ticket(
    id: id,
    eventId: eventId,
    holderId: holder.id,
    holderName: holder.name,
    status: status,
    createdAt: now.subtract(const Duration(hours: 1)),
    code: 'T20-${id.value}',
  );
}

/// A reservation with [left] time until it expires; negative means it already expired.
Reserved reserved({Duration left = const Duration(minutes: 10)}) => Reserved(expiresAt: now.add(left));

Paid paid() => Paid(paidAt: now.subtract(const Duration(hours: 1)));

Used used() => Used(scannedAt: now.subtract(const Duration(minutes: 30)), scannedBy: usher.id);

Cancelled cancelled() => Cancelled(at: now.subtract(const Duration(hours: 2)), by: ana.id);

Expired expired() => Expired(at: now.subtract(const Duration(hours: 3)));
