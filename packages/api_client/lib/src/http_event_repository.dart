import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpEventRepository implements EventRepository {
  const HttpEventRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Event>> upcoming() async {
    final answer = await _api.get(ApiPaths.events);
    return accepted(answer, (json) => [for (final item in objects(json)) EventDto.fromJson(item).toDomain()]);
  }

  @override
  Future<Event?> findEvent(EventId id) async {
    final answer = await _api.get(ApiPaths.event(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, (json) => EventDto.fromJson(object(json)).toDomain());
  }

  /// The server counts with its own clock over every ticket, so [now] stays on the device.
  @override
  Future<int> remainingSeats(EventId id, {required DateTime now}) async {
    final answer = await _api.get(ApiPaths.seats(id.value));
    return accepted(answer, (json) => SeatsDto.fromJson(object(json)).remaining);
  }
}
