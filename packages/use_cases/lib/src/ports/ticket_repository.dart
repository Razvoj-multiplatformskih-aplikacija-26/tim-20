import 'package:domain/domain.dart';

abstract interface class TicketRepository {
  Future<List<Ticket>> ticketsOf(UserId holderId);

  Future<List<Ticket>> ticketsFor(EventId eventId);

  Future<Ticket?> findTicket(TicketId id);

  /// Runs reserveTickets over the stored tickets of the event and stores the new ones, as one step for every caller
  /// at once. The seats depend on other visitors, so only the store that sees every ticket can decide.
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  });

  /// Stores [ticket] only if the stored status is still of the same kind as [from];
  /// otherwise fails with InvalidTransition from the stored status.
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from});
}
