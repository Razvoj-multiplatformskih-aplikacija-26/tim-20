import 'package:domain/domain.dart';

/// The payment provider. Only the server talks to it, so its key never reaches a device.
abstract interface class PaymentGateway {
  /// Throws RepositoryException when the provider does not answer.
  Future<void> charge({required TicketId ticketId, required int amountRsd});
}
