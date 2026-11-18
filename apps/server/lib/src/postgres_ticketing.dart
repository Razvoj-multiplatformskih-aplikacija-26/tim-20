import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain show remainingSeats;
import 'package:postgres/postgres.dart' show Pool;
import 'package:use_cases/use_cases.dart';

import 'ticketing_store.dart';

/// The same ports as the fakes in the apps, over PostgreSQL. The rules are decided by the domain.
final class PostgresTicketing implements EventRepository, TicketRepository {
  PostgresTicketing(Pool<void> database) : _store = TicketingStore(database);

  final TicketingStore _store;

  @override
  Future<List<Event>> upcoming() => _store.events();

  @override
  Future<Event?> findEvent(EventId id) => _store.event(id);

  @override
  Future<int> remainingSeats(EventId id, {required DateTime now}) async {
    final event = await _store.event(id);
    if (event == null) return 0;
    return domain.remainingSeats(event, await _store.ticketsOfEvent(id), now: now);
  }

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) => _store.ticketsOf(holderId);

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) => _store.ticketsOfEvent(eventId);

  @override
  Future<Ticket?> findTicket(TicketId id) => _store.ticket(id);

  Future<User?> user(UserId id) => _store.user(id);

  @override
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  }) => throw UnimplementedError('Reservations arrive with the writes');

  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) =>
      throw UnimplementedError('Status changes arrive with the writes');
}
