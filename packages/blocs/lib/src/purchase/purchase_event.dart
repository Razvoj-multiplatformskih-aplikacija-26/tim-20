part of 'purchase_bloc.dart';

sealed class PurchaseEvent {
  const PurchaseEvent();
}

final class PurchaseStarted extends PurchaseEvent {
  const PurchaseStarted(this.eventId);

  final EventId eventId;
}
