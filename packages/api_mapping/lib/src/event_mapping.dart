import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension EventMapping on Event {
  EventDto toDto() => EventDto(
    id: id.value,
    name: name,
    venue: venue,
    startsAt: startsAt,
    price: MoneyDto(amount: priceRsd, currency: MoneyDto.rsd),
    capacity: capacity,
    organizerId: organizerId.value,
  );
}

extension EventDtoMapping on EventDto {
  Event toDomain() {
    if (price.currency != MoneyDto.rsd) throw FormatException('Prices are in dinars', price.currency);
    return Event(
      id: EventId(id),
      name: name,
      venue: venue,
      startsAt: startsAt,
      priceRsd: price.amount,
      capacity: capacity,
      organizerId: UserId(organizerId),
    );
  }
}
