import 'package:meta/meta.dart';

import 'identifiers.dart';
import 'ticket.dart';

sealed class TicketStatus {
  const TicketStatus();

  /// Takes a seat and counts toward the limit of tickets per visitor.
  bool get isActive => switch (this) {
    Reserved() || Paid() || Used() => true,
    Cancelled() || Expired() => false,
  };

  bool get isFinal => switch (this) {
    Used() || Cancelled() || Expired() => true,
    Reserved() || Paid() => false,
  };
}

@immutable
final class Reserved extends TicketStatus {
  const Reserved({required this.expiresAt});

  final DateTime expiresAt;

  @override
  bool operator ==(Object other) => other is Reserved && other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(Reserved, expiresAt);

  @override
  String toString() => 'Reserved(until $expiresAt)';
}

@immutable
final class Paid extends TicketStatus {
  const Paid({required this.paidAt, this.confirmedBy});

  final DateTime paidAt;

  /// Set when an organizer confirmed the payment by hand.
  final UserId? confirmedBy;

  @override
  bool operator ==(Object other) => other is Paid && other.paidAt == paidAt && other.confirmedBy == confirmedBy;

  @override
  int get hashCode => Object.hash(Paid, paidAt, confirmedBy);

  @override
  String toString() => 'Paid(at $paidAt${confirmedBy == null ? '' : ', confirmed by $confirmedBy'})';
}

@immutable
final class Used extends TicketStatus {
  const Used({required this.scannedAt, required this.scannedBy});

  final DateTime scannedAt;
  final UserId scannedBy;

  @override
  bool operator ==(Object other) => other is Used && other.scannedAt == scannedAt && other.scannedBy == scannedBy;

  @override
  int get hashCode => Object.hash(Used, scannedAt, scannedBy);

  @override
  String toString() => 'Used(at $scannedAt by $scannedBy)';
}

@immutable
final class Cancelled extends TicketStatus {
  const Cancelled({required this.at, required this.by, this.reason = ''});

  final DateTime at;
  final UserId by;
  final String reason;

  @override
  bool operator ==(Object other) => other is Cancelled && other.at == at && other.by == by && other.reason == reason;

  @override
  int get hashCode => Object.hash(Cancelled, at, by, reason);

  @override
  String toString() => 'Cancelled("$reason" by $by at $at)';
}

@immutable
final class Expired extends TicketStatus {
  const Expired({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is Expired && other.at == at;

  @override
  int get hashCode => Object.hash(Expired, at);

  @override
  String toString() => 'Expired(at $at)';
}

bool canTransition(TicketStatus from, TicketStatus to) => switch ((from, to)) {
  (Reserved(), Paid()) => true,
  (Reserved(), Expired()) => true,
  (Reserved() || Paid(), Cancelled()) => true,
  (Paid(), Used()) => true,
  _ => false,
};

/// The status as it is at [now]: a reservation past its deadline is expired, even if it was stored as reserved.
TicketStatus effectiveStatus(Ticket ticket, {required DateTime now}) {
  final status = ticket.status;
  if (status is Reserved && now.isAfter(status.expiresAt)) return Expired(at: status.expiresAt);
  return status;
}
