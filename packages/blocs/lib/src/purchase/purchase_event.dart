part of 'purchase_bloc.dart';

sealed class PurchaseEvent {
  const PurchaseEvent();
}

final class PurchaseStarted extends PurchaseEvent {
  const PurchaseStarted(this.eventId);

  final EventId eventId;
}

final class PurchaseQuantityChanged extends PurchaseEvent {
  const PurchaseQuantityChanged(this.quantity);

  final int quantity;
}

final class PurchaseSubmitted extends PurchaseEvent {
  const PurchaseSubmitted();
}
