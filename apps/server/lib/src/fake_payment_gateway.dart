import 'dart:io';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// Stands in for the payment provider in KT2. The key comes from .env and stays on the server.
final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({required String apiKey}) {
    if (apiKey.isEmpty) throw StateError('PAYMENT_API_KEY is empty. Copy .env.example to .env.');
  }

  @override
  Future<void> charge({required TicketId ticketId, required int amountRsd}) async {
    stdout.writeln('charged ${ticketId.value} $amountRsd RSD');
  }
}
