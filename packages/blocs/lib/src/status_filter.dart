import 'package:domain/domain.dart';

enum StatusFilter {
  all,
  reserved,
  paid,
  used,
  cancelled,
  expired;

  /// [status] is the effective status, as returned by the use cases.
  bool matches(TicketStatus status) => switch (this) {
    all => true,
    reserved => status is Reserved,
    paid => status is Paid,
    used => status is Used,
    cancelled => status is Cancelled,
    expired => status is Expired,
  };
}
