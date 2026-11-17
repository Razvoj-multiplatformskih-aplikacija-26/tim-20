import 'package:meta/meta.dart';

import 'ticket_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
/// The rule carries its limits, so a message shows the limits of whoever checked it, the client or the server.
@immutable
final class InvalidTicketQuantity extends DomainError {
  const InvalidTicketQuantity(this.requested, {required this.min, required this.max});

  final int requested;
  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is InvalidTicketQuantity && other.requested == requested && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(InvalidTicketQuantity, requested, min, max);

  @override
  String toString() => 'InvalidTicketQuantity($requested, from $min to $max)';
}

@immutable
final class TicketLimitExceeded extends DomainError {
  const TicketLimitExceeded({required this.alreadyHeld, required this.requested, required this.max});

  final int alreadyHeld;
  final int requested;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is TicketLimitExceeded &&
      other.alreadyHeld == alreadyHeld &&
      other.requested == requested &&
      other.max == max;

  @override
  int get hashCode => Object.hash(TicketLimitExceeded, alreadyHeld, requested, max);

  @override
  String toString() => 'TicketLimitExceeded(held $alreadyHeld, requested $requested, max $max)';
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

@immutable
final class CancellationTooLate extends DomainError {
  const CancellationTooLate({required this.notice});

  final Duration notice;

  @override
  bool operator ==(Object other) => other is CancellationTooLate && other.notice == notice;

  @override
  int get hashCode => Object.hash(CancellationTooLate, notice);

  @override
  String toString() => 'CancellationTooLate(notice $notice)';
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
