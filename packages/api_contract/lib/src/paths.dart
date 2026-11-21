abstract final class ApiPaths {
  static const health = '/health';
  static const sessions = '/api/v1/sessions';
  static const currentSession = '/api/v1/sessions/current';
  static const events = '/api/v1/events';
  static const tickets = '/api/v1/tickets';

  static String event(String id) => '$events/$id';

  static String seats(String eventId) => '${event(eventId)}/seats';

  static String eventTickets(String eventId) => '${event(eventId)}/tickets';

  static String reservations(String eventId) => '${event(eventId)}/reservations';

  static String ticketsOfUser(String userId) => '/api/v1/users/$userId/tickets';

  static String ticket(String id) => '$tickets/$id';

  static String payment(String id) => '${ticket(id)}/payment';

  static String paymentConfirmation(String id) => '${ticket(id)}/payment-confirmation';

  static String admission(String id) => '${ticket(id)}/admission';

  static String cancellation(String id) => '${ticket(id)}/cancellation';
}

abstract final class ApiCookies {
  static const session = 'tim20_session';
}
