part of 'purchase_bloc.dart';

sealed class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class PurchaseLoading extends PurchaseState {
  const PurchaseLoading();
}

final class PurchaseFailure extends PurchaseState {
  const PurchaseFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'PurchaseFailure($cause)';
}

final class PurchaseNotFound extends PurchaseState {
  const PurchaseNotFound();
}

final class PurchaseReady extends PurchaseState {
  const PurchaseReady({
    required this.context,
    this.quantity = 1,
    this.validation,
    this.submitting = false,
    this.rejection,
  });

  final PurchaseContext context;
  final int quantity;

  /// The rule the quantity breaks while the visitor types, if any.
  final DomainError? validation;
  final bool submitting;

  /// The rule the reservation broke on submit, for example seats taken in the meantime.
  final DomainError? rejection;

  bool get canSubmit => validation == null && !submitting;

  @override
  List<Object?> get props => [context, quantity, validation, submitting, rejection];

  @override
  String toString() => [
    'PurchaseReady(${context.event.name}, $quantity',
    if (validation case final error?) ', invalid: $error',
    if (submitting) ', submitting',
    if (rejection case final error?) ', rejected: $error',
    ')',
  ].join();

  PurchaseReady copyWith({bool? submitting, DomainError? rejection}) => PurchaseReady(
    context: context,
    quantity: quantity,
    validation: validation,
    submitting: submitting ?? this.submitting,
    rejection: rejection,
  );
}

final class PurchaseCompleted extends PurchaseState {
  const PurchaseCompleted(this.tickets);

  final List<Ticket> tickets;

  @override
  List<Object?> get props => [tickets];

  @override
  String toString() => 'PurchaseCompleted(${tickets.length} tickets)';
}
