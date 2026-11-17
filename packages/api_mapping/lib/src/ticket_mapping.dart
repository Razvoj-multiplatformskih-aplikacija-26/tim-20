import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension TicketStatusMapping on TicketStatus {
  TicketStatusDto toDto() => switch (this) {
    Reserved(:final expiresAt) => TicketStatusDto(kind: TicketStatusDto.reserved, expiresAt: expiresAt),
    Paid(:final paidAt, :final confirmedBy) => TicketStatusDto(
      kind: TicketStatusDto.paid,
      at: paidAt,
      by: confirmedBy?.value,
    ),
    Used(:final scannedAt, :final scannedBy) => TicketStatusDto(
      kind: TicketStatusDto.used,
      at: scannedAt,
      by: scannedBy.value,
    ),
    Cancelled(:final at, :final by, :final reason) => TicketStatusDto(
      kind: TicketStatusDto.cancelled,
      at: at,
      by: by.value,
      reason: reason,
    ),
    Expired(:final at) => TicketStatusDto(kind: TicketStatusDto.expired, at: at),
  };
}

extension TicketStatusDtoMapping on TicketStatusDto {
  /// The kind is a string from the wire, so an unknown one is a format error and not a missing case.
  TicketStatus toDomain() => switch (this) {
    TicketStatusDto(kind: TicketStatusDto.reserved, :final expiresAt?) => Reserved(expiresAt: expiresAt),
    TicketStatusDto(kind: TicketStatusDto.paid, :final at?, :final by) => Paid(
      paidAt: at,
      confirmedBy: by == null ? null : UserId(by),
    ),
    TicketStatusDto(kind: TicketStatusDto.used, :final at?, :final by?) => Used(scannedAt: at, scannedBy: UserId(by)),
    TicketStatusDto(kind: TicketStatusDto.cancelled, :final at?, :final by?, :final reason) => Cancelled(
      at: at,
      by: UserId(by),
      reason: reason ?? '',
    ),
    TicketStatusDto(kind: TicketStatusDto.expired, :final at?) => Expired(at: at),
    _ => throw FormatException('Unknown ticket status', kind),
  };
}

extension TicketMapping on Ticket {
  TicketDto toDto() => TicketDto(
    id: id.value,
    eventId: eventId.value,
    holderId: holderId.value,
    holderName: holderName,
    status: status.toDto(),
    createdAt: createdAt,
    code: code,
  );
}

extension TicketDtoMapping on TicketDto {
  Ticket toDomain() => Ticket(
    id: TicketId(id),
    eventId: EventId(eventId),
    holderId: UserId(holderId),
    holderName: holderName,
    status: status.toDomain(),
    createdAt: createdAt,
    code: code,
  );
}
