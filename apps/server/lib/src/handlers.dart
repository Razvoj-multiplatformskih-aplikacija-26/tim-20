import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'postgres_ticketing.dart';
import 'sessions.dart';

/// Each handler reads the call, runs the same use case as the apps and answers; the rules stay in the domain.
final class TicketingHandlers {
  TicketingHandlers({required this.ticketing, required this.clock, required PaymentGateway payments})
    : _reserveTickets = ReserveTickets(events: ticketing, tickets: ticketing, clock: clock),
      _payTicket = PayTicket(events: ticketing, tickets: ticketing, clock: clock, payments: payments),
      _confirmPayment = ConfirmPayment(events: ticketing, tickets: ticketing, clock: clock),
      _admitTicket = AdmitTicket(events: ticketing, tickets: ticketing, clock: clock),
      _cancelTicket = CancelTicket(events: ticketing, tickets: ticketing, clock: clock);

  final PostgresTicketing ticketing;
  final Clock clock;
  final ReserveTickets _reserveTickets;
  final PayTicket _payTicket;
  final ConfirmPayment _confirmPayment;
  final AdmitTicket _admitTicket;
  final CancelTicket _cancelTicket;

  Future<Response> events(Request request) async =>
      json(200, [for (final event in await ticketing.upcoming()) event.toDto().toJson()]);

  Future<Response> event(Request request) async {
    final event = await ticketing.findEvent(_eventId(request));
    if (event == null) return problem(const NotFound());
    return json(200, event.toDto().toJson());
  }

  Future<Response> seats(Request request) async {
    final id = _eventId(request);
    if (await ticketing.findEvent(id) == null) return problem(const NotFound());
    final remaining = await ticketing.remainingSeats(id, now: clock.now());
    return json(200, SeatsDto(remaining: remaining).toJson());
  }

  Future<Response> eventTickets(Request request) async {
    final actor = _actor(request);
    if (!AccessPolicy.canViewEventTickets(actor)) return problem(const NotAllowed());
    final id = _eventId(request);
    final event = await ticketing.findEvent(id);
    if (event == null || !AccessPolicy.canListEvent(actor, event)) return problem(const NotFound());
    return json(200, [for (final ticket in await ticketing.ticketsFor(id)) ticket.toDto().toJson()]);
  }

  Future<Response> ticketsOfUser(Request request) async {
    final actor = _actor(request);
    final tickets = await ticketing.ticketsOf(UserId(request.rawPathParameters[#userId]!));
    return json(200, [
      for (final ticket in tickets)
        if (AccessPolicy.canView(actor, ticket)) ticket.toDto().toJson(),
    ]);
  }

  Future<Response> ticket(Request request) async {
    final ticket = await ticketing.findTicket(_ticketId(request));
    if (ticket == null || !AccessPolicy.canView(_actor(request), ticket)) return problem(const NotFound());
    return json(200, ticket.toDto().toJson());
  }

  Future<Response> reserve(Request request) async {
    final body = NewReservationDto.fromJson(await readObject(request));
    final reserved = await _reserveTickets(eventId: _eventId(request), by: _actor(request), quantity: body.quantity);
    return respondCreated(reserved);
  }

  Future<Response> payment(Request request) async =>
      respond(await _payTicket(id: _ticketId(request), by: _actor(request)));

  Future<Response> paymentConfirmation(Request request) async =>
      respond(await _confirmPayment(id: _ticketId(request), by: _actor(request)));

  Future<Response> admission(Request request) async =>
      respond(await _admitTicket(id: _ticketId(request), by: _actor(request)));

  Future<Response> cancellation(Request request) async {
    final body = CancellationDto.fromJson(await readObject(request));
    return respond(await _cancelTicket(id: _ticketId(request), by: _actor(request), reason: body.reason));
  }

  User _actor(Request request) => currentSession.get(request).user;

  EventId _eventId(Request request) => EventId(request.rawPathParameters[#id]!);

  TicketId _ticketId(Request request) => TicketId(request.rawPathParameters[#id]!);
}
