import 'package:domain/domain.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    InvalidTicketQuantity(:final min, :final max) => 'Broj karata je od $min do $max.',
    TicketLimitExceeded(:final max, :final alreadyHeld) =>
      'Za jedan događaj možete imati najviše $max karte (već imate $alreadyHeld).',
    NotEnoughSeats(:final remaining) => remaining == 0 ? 'Karte su rasprodate.' : 'Preostalo je još $remaining mesta.',
    EventAlreadyStarted() => 'Događaj je već počeo.',
    CancellationTooLate(:final notice) => 'Kartu možete otkazati najkasnije ${notice.inHours} sata pre početka.',
    ReservationExpired() => 'Rezervacija je istekla jer karta nije plaćena na vreme.',
    TicketAlreadyUsed() => 'Karta je već iskorišćena.',
    InvalidTransition() => 'Ova promena karte nije moguća.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    NotFound() => 'Karta nije pronađena.',
  };
}
