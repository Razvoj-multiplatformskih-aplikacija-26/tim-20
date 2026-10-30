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
