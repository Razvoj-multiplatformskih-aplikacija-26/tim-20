import 'package:domain/domain.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    InvalidTicketQuantity() => 'Broj karata je od ${TicketQuantity.min} do ${TicketQuantity.max}.',
    TicketLimitExceeded(:final alreadyHeld) =>
      'Za jedan događaj možete imati najviše $maxTicketsPerEvent karte (već imate $alreadyHeld).',
    NotEnoughSeats(:final remaining) => remaining == 0 ? 'Karte su rasprodate.' : 'Preostalo je još $remaining mesta.',
    EventAlreadyStarted() => 'Događaj je već počeo.',
    CancellationTooLate() => 'Kartu možete otkazati najkasnije ${cancellationNotice.inHours} sata pre početka.',
    ReservationExpired() => 'Rezervacija je istekla jer karta nije plaćena na vreme.',
    TicketAlreadyUsed() => 'Karta je već iskorišćena.',
    InvalidTransition() => 'Ova promena karte nije moguća.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    NotFound() => 'Karta nije pronađena.',
  };
}
