import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpTicketRepository implements TicketRepository {
  const HttpTicketRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Ticket>> ticketsOf(UserId holderId) async {
    final answer = await _api.get(ApiPaths.ticketsOfUser(holderId.value));
    return accepted(answer, _tickets);
  }

  @override
  Future<List<Ticket>> ticketsFor(EventId eventId) async {
    final answer = await _api.get(ApiPaths.eventTickets(eventId.value));
    return accepted(answer, _tickets);
  }

  @override
  Future<Ticket?> findTicket(TicketId id) async {
    final answer = await _api.get(ApiPaths.ticket(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, _ticket);
  }

  /// The server runs the rule over every ticket with its own clock, so [by] and [now] come from the session there.
  @override
  Future<Result<List<Ticket>>> reserve({
    required EventId eventId,
    required User by,
    required int quantity,
    required DateTime now,
  }) async {
    final body = NewReservationDto(quantity: quantity).toJson();
    return resultOf(await _api.post(ApiPaths.reservations(eventId.value), body: body), _tickets);
  }

  /// Each status change is its own action on the server, which checks the stored status itself.
  @override
  Future<Result<Ticket>> save(Ticket ticket, {required TicketStatus from}) async {
    final id = ticket.id.value;
    final answer = await switch (ticket.status) {
      Paid(confirmedBy: null) => _api.post(ApiPaths.payment(id)),
      Paid() => _api.post(ApiPaths.paymentConfirmation(id)),
      Used() => _api.post(ApiPaths.admission(id)),
      Cancelled(:final reason) => _api.post(ApiPaths.cancellation(id), body: CancellationDto(reason: reason).toJson()),
      Reserved() => throw ArgumentError.value(ticket, 'ticket', 'A reservation is created, not saved'),
      Expired() => throw ArgumentError.value(ticket, 'ticket', 'A reservation expires on the server by itself'),
    };
    return resultOf(answer, _ticket);
  }

  Ticket _ticket(Object? json) => TicketDto.fromJson(object(json)).toDomain();

  List<Ticket> _tickets(Object? json) => [for (final item in objects(json)) TicketDto.fromJson(item).toDomain()];
}
