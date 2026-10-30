import 'package:domain/domain.dart';

extension TicketStatusLabel on TicketStatus {
  String get label => switch (this) {
    Reserved() => 'Rezervisana',
    Paid() => 'Plaćena',
    Used() => 'Iskorišćena',
    Cancelled() => 'Otkazana',
    Expired() => 'Istekla',
  };
}
