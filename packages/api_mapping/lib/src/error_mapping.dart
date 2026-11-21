import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'ticket_mapping.dart';

extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    InvalidTicketQuantity(:final requested, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidTicketQuantity,
      title: 'Invalid ticket quantity',
      value: requested,
      min: min,
      max: max,
    ),
    TicketLimitExceeded(:final alreadyHeld, :final requested, :final max) => ProblemDto(
      status: 409,
      code: ErrorCodes.ticketLimitExceeded,
      title: 'Ticket limit exceeded',
      held: alreadyHeld,
      value: requested,
      max: max,
    ),
    NotEnoughSeats(:final remaining) => ProblemDto(
      status: 409,
      code: ErrorCodes.notEnoughSeats,
      title: 'Not enough seats',
      value: remaining,
    ),
    EventAlreadyStarted() => const ProblemDto(
      status: 422,
      code: ErrorCodes.eventAlreadyStarted,
      title: 'Event already started',
    ),
    CancellationTooLate(:final notice) => ProblemDto(
      status: 422,
      code: ErrorCodes.cancellationTooLate,
      title: 'Cancellation too late',
      min: notice.inMinutes,
    ),
    ReservationExpired() => const ProblemDto(
      status: 409,
      code: ErrorCodes.reservationExpired,
      title: 'Reservation expired',
    ),
    TicketAlreadyUsed() => const ProblemDto(
      status: 409,
      code: ErrorCodes.ticketAlreadyUsed,
      title: 'Ticket already used',
    ),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.toDto(),
      to: to.toDto(),
    ),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    NotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

extension ProblemMapping on ProblemDto {
  /// Null for a code this client does not know, or for a known code without the data of its rule.
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.invalidTicketQuantity, :final value?, :final min?, :final max?) =>
      InvalidTicketQuantity(value, min: min, max: max),
    ProblemDto(code: ErrorCodes.ticketLimitExceeded, :final held?, :final value?, :final max?) => TicketLimitExceeded(
      alreadyHeld: held,
      requested: value,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.notEnoughSeats, :final value?) => NotEnoughSeats(value),
    ProblemDto(code: ErrorCodes.eventAlreadyStarted) => const EventAlreadyStarted(),
    ProblemDto(code: ErrorCodes.cancellationTooLate, :final min?) => CancellationTooLate(
      notice: Duration(minutes: min),
    ),
    ProblemDto(code: ErrorCodes.reservationExpired) => const ReservationExpired(),
    ProblemDto(code: ErrorCodes.ticketAlreadyUsed) => const TicketAlreadyUsed(),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => InvalidTransition(
      from: from.toDomain(),
      to: to.toDomain(),
    ),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    _ => null,
  };
}
