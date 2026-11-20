import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain show remainingSeats;
import 'package:postgres/postgres.dart' show Pool;
import 'package:use_cases/use_cases.dart';

import 'ticket_ids.dart';
import 'ticketing_store.dart';

/// The same ports as the fakes in the apps, over PostgreSQL. The rules are decided by the domain.
final class PostgresTicketing implements EventRepository, TicketRepository {
  PostgresTicketing(this._database) : _store = TicketingStore(_database);

  final Pool<void> _database;
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
  }) => _database.runTx((session) async {
    final store = TicketingStore(session);
    final event = await store.lockEvent(eventId);
    if (event == null) return const Failure(NotFound());
    final result = reserveTickets(
      event: event,
      ticketsOfEvent: await store.ticketsOfEvent(eventId),
      by: by,
      quantity: quantity,
      now: now,
      newId: newTicketId,
    );
    if (result case Success(:final value)) {
      for (final ticket in value) {
        await store.insertTicket(ticket);
      }
    }
    return result;
  });

  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) async {
    if (await _store.changeStatus(ticket, from: from)) return Success(ticket);
    final stored = await _store.ticket(ticket.id);
    if (stored == null) return const Failure(NotFound());
    return Failure(InvalidTransition(from: stored.status, to: ticket.status));
  }
}
