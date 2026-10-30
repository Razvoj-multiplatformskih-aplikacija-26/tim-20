import 'package:domain/domain.dart';

abstract interface class TicketRepository {
  Future<List<Ticket>> ticketsOf(UserId holderId);

  Future<List<Ticket>> ticketsFor(EventId eventId);

  Future<Ticket?> findTicket(TicketId id);

  /// Stores new or changed tickets and returns them as stored.
  Future<List<Ticket>> saveAll(List<Ticket> tickets);
}
