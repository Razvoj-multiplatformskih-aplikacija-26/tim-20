import 'json.dart';
import 'ticket_dto.dart';

/// An error as Problem Details (RFC 9457): the code and the data of the rule, never a message for the user.
final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.min,
    this.max,
    this.held,
    this.from,
    this.to,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:tim-20/problem/$code';

  final int status;
  final String code;
  final String title;
  final int? value;
  final int? min;
  final int? max;
  final int? held;
  final TicketStatusDto? from;
  final TicketStatusDto? to;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'min': ?min,
    'max': ?max,
    'held': ?held,
    if (from case final from?) 'from': from.toJson(),
    if (to case final to?) 'to': to.toJson(),
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    min: jsonOptionalInt(json, 'min'),
    max: jsonOptionalInt(json, 'max'),
    held: jsonOptionalInt(json, 'held'),
    from: json['from'] == null ? null : TicketStatusDto.fromJson(jsonObject(json['from'])),
    to: json['to'] == null ? null : TicketStatusDto.fromJson(jsonObject(json['to'])),
  );
}
