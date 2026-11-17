import 'package:domain/domain.dart';

import 'change_ticket.dart';
import 'clock.dart';
import 'ports/event_repository.dart';
import 'ports/payment_gateway.dart';
import 'ports/ticket_repository.dart';

final class PayTicket {
  const PayTicket({required this.events, required this.tickets, required this.clock, this.payments});

  final EventRepository events;
  final TicketRepository tickets;
  final Clock clock;

  /// Only the server charges; a client sends the payment to the server and has no gateway.
  final PaymentGateway? payments;

  Future<Result<Ticket>> call({required TicketId id, required User by}) {
    var charged = false;
    return changeTicket(
      tickets,
      id,
      by: by,
      change: (ticket) => payTicket(ticket, by: by, now: clock.now()),
      beforeSave: (paid) async {
        final payments = this.payments;
        final event = await events.findEvent(paid.eventId);
        if (payments == null || event == null || charged) return;
        await payments.charge(ticketId: paid.id, amountRsd: event.priceRsd);
        charged = true;
      },
    );
  }
}
