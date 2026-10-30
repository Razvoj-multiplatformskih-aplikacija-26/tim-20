import 'package:meta/meta.dart';

import 'identifiers.dart';
import 'ticket_status.dart';

@immutable
final class Ticket {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.holderId,
    required this.holderName,
    required this.status,
    required this.createdAt,
    required this.code,
  });

  final TicketId id;
  final EventId eventId;
  final UserId holderId;
  final String holderName;
  final TicketStatus status;
  final DateTime createdAt;

  /// Content of the QR code, scanned at the entrance.
  final String code;

  bool isActiveAt(DateTime now) => effectiveStatus(this, now: now).isActive;

  Ticket copyWith({TicketStatus? status}) {
    return Ticket(
      id: id,
      eventId: eventId,
      holderId: holderId,
      holderName: holderName,
      status: status ?? this.status,
      createdAt: createdAt,
      code: code,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Ticket &&
      other.id == id &&
      other.eventId == eventId &&
      other.holderId == holderId &&
      other.holderName == holderName &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.code == code;

  @override
  int get hashCode => Object.hash(id, eventId, holderId, holderName, status, createdAt, code);

  @override
  String toString() => 'Ticket($id, $holderName, $status)';
}
