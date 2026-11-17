import 'json.dart';

/// An amount in whole units of the currency, so no rounding happens on the way.
final class MoneyDto {
  const MoneyDto({required this.amount, required this.currency});

  static const rsd = 'RSD';

  final int amount;
  final String currency;

  Map<String, Object?> toJson() => {'amount': amount, 'currency': currency};

  factory MoneyDto.fromJson(Map<String, Object?> json) =>
      MoneyDto(amount: jsonInt(json, 'amount'), currency: jsonString(json, 'currency'));
}

final class EventDto {
  const EventDto({
    required this.id,
    required this.name,
    required this.venue,
    required this.startsAt,
    required this.price,
    required this.capacity,
    required this.organizerId,
  });

  final String id;
  final String name;
  final String venue;
  final DateTime startsAt;
  final MoneyDto price;
  final int capacity;
  final String organizerId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'venue': venue,
    'startsAt': instantToJson(startsAt),
    'price': price.toJson(),
    'capacity': capacity,
    'organizerId': organizerId,
  };

  factory EventDto.fromJson(Map<String, Object?> json) => EventDto(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    venue: jsonString(json, 'venue'),
    startsAt: jsonInstant(json, 'startsAt'),
    price: MoneyDto.fromJson(jsonObject(json['price'])),
    capacity: jsonInt(json, 'capacity'),
    organizerId: jsonString(json, 'organizerId'),
  );
}

/// Only the number of free seats, so a visitor never receives the tickets of others.
final class SeatsDto {
  const SeatsDto({required this.remaining});

  final int remaining;

  Map<String, Object?> toJson() => {'remaining': remaining};

  factory SeatsDto.fromJson(Map<String, Object?> json) => SeatsDto(remaining: jsonInt(json, 'remaining'));
}
