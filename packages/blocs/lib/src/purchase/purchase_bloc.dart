import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'purchase_event.dart';
part 'purchase_state.dart';

// D4
final class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  PurchaseBloc({required this.getPurchaseContext, required this.reserveTickets, required this.visitor})
    : super(const PurchaseLoading());

  final GetPurchaseContext getPurchaseContext;
  final ReserveTickets reserveTickets;
  final User visitor;
}
