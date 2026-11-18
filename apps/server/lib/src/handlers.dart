import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'postgres_ticketing.dart';

final class TicketingHandlers {
  TicketingHandlers({required this.ticketing, required this.clock});

  final PostgresTicketing ticketing;
  final Clock clock;

  Future<Response> events(Request request) async =>
      json(200, [for (final event in await ticketing.upcoming()) event.toDto().toJson()]);

  Future<Response> event(Request request) async {
    final event = await ticketing.findEvent(EventId(request.rawPathParameters[#id]!));
    if (event == null) return problem(const NotFound());
    return json(200, event.toDto().toJson());
  }

  Future<Response> seats(Request request) async {
    final id = EventId(request.rawPathParameters[#id]!);
    if (await ticketing.findEvent(id) == null) return problem(const NotFound());
    final remaining = await ticketing.remainingSeats(id, now: clock.now());
    return json(200, SeatsDto(remaining: remaining).toJson());
  }
}
