import 'json.dart';

final class TicketStatusDto {
  const TicketStatusDto({required this.kind, this.at, this.by, this.expiresAt, this.reason});

  static const reserved = 'reserved';
  static const paid = 'paid';
  static const used = 'used';
  static const cancelled = 'cancelled';
  static const expired = 'expired';

  final String kind;
  final DateTime? at;
  final String? by;
  final DateTime? expiresAt;
  final String? reason;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (at case final at?) 'at': instantToJson(at),
    'by': ?by,
    if (expiresAt case final expiresAt?) 'expiresAt': instantToJson(expiresAt),
    'reason': ?reason,
  };

  factory TicketStatusDto.fromJson(Map<String, Object?> json) => TicketStatusDto(
    kind: jsonString(json, 'kind'),
    at: jsonOptionalInstant(json, 'at'),
    by: jsonOptionalString(json, 'by'),
    expiresAt: jsonOptionalInstant(json, 'expiresAt'),
    reason: jsonOptionalString(json, 'reason'),
  );
}

final class TicketDto {
  const TicketDto({
    required this.id,
    required this.eventId,
    required this.holderId,
    required this.holderName,
    required this.status,
    required this.createdAt,
    required this.code,
  });

  final String id;
  final String eventId;
  final String holderId;
  final String holderName;
  final TicketStatusDto status;
  final DateTime createdAt;
  final String code;

  Map<String, Object?> toJson() => {
    'id': id,
    'eventId': eventId,
    'holderId': holderId,
    'holderName': holderName,
    'status': status.toJson(),
    'createdAt': instantToJson(createdAt),
    'code': code,
  };

  factory TicketDto.fromJson(Map<String, Object?> json) => TicketDto(
    id: jsonString(json, 'id'),
    eventId: jsonString(json, 'eventId'),
    holderId: jsonString(json, 'holderId'),
    holderName: jsonString(json, 'holderName'),
    status: TicketStatusDto.fromJson(jsonObject(json['status'])),
    createdAt: jsonInstant(json, 'createdAt'),
    code: jsonString(json, 'code'),
  );
}

final class NewReservationDto {
  const NewReservationDto({required this.quantity});

  final int quantity;

  Map<String, Object?> toJson() => {'quantity': quantity};

  factory NewReservationDto.fromJson(Map<String, Object?> json) =>
      NewReservationDto(quantity: jsonInt(json, 'quantity'));
}

final class CancellationDto {
  const CancellationDto({this.reason = ''});

  final String reason;

  Map<String, Object?> toJson() => {'reason': reason};

  factory CancellationDto.fromJson(Map<String, Object?> json) =>
      CancellationDto(reason: jsonOptionalString(json, 'reason') ?? '');
}
