import 'package:meta/meta.dart';

import 'ticket_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class InvalidTicketQuantity extends DomainError {
  const InvalidTicketQuantity(this.requested);

  final int requested;

  @override
  bool operator ==(Object other) => other is InvalidTicketQuantity && other.requested == requested;

  @override
  int get hashCode => Object.hash(InvalidTicketQuantity, requested);

  @override
  String toString() => 'InvalidTicketQuantity($requested)';
}

@immutable
final class TicketLimitExceeded extends DomainError {
  const TicketLimitExceeded({required this.alreadyHeld, required this.requested});

  final int alreadyHeld;
  final int requested;

  @override
  bool operator ==(Object other) =>
      other is TicketLimitExceeded && other.alreadyHeld == alreadyHeld && other.requested == requested;

  @override
  int get hashCode => Object.hash(TicketLimitExceeded, alreadyHeld, requested);

  @override
  String toString() => 'TicketLimitExceeded(held $alreadyHeld, requested $requested)';
}

@immutable
final class NotEnoughSeats extends DomainError {
  const NotEnoughSeats(this.remaining);

  final int remaining;

  @override
  bool operator ==(Object other) => other is NotEnoughSeats && other.remaining == remaining;

  @override
  int get hashCode => Object.hash(NotEnoughSeats, remaining);

  @override
  String toString() => 'NotEnoughSeats($remaining)';
}

final class EventAlreadyStarted extends DomainError {
  const EventAlreadyStarted();
}

final class CancellationTooLate extends DomainError {
  const CancellationTooLate();
}

final class ReservationExpired extends DomainError {
  const ReservationExpired();
}

final class TicketAlreadyUsed extends DomainError {
  const TicketAlreadyUsed();
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final TicketStatus from;
  final TicketStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}
