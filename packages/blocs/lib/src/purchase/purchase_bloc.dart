import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'purchase_event.dart';
part 'purchase_state.dart';

final class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  PurchaseBloc({required this.getPurchaseContext, required this.reserveTickets, required this.visitor})
    : super(const PurchaseLoading()) {
    on<PurchaseStarted>((event, emit) async {
      emit(const PurchaseLoading());
      try {
        final context = await getPurchaseContext(eventId: event.eventId, holder: visitor.id);
        emit(context == null ? const PurchaseNotFound() : _ready(context, 1));
      } on Exception catch (cause) {
        emit(PurchaseFailure(cause));
      }
    });
    on<PurchaseQuantityChanged>((event, emit) {
      final current = state;
      if (current is PurchaseReady && !current.submitting) emit(_ready(current.context, event.quantity));
    });
    on<PurchaseSubmitted>(_onSubmitted);
  }

  final GetPurchaseContext getPurchaseContext;
  final ReserveTickets reserveTickets;
  final User visitor;

  /// The form is checked with the rule from the domain; the screen only shows the message.
  PurchaseReady _ready(PurchaseContext context, int quantity) => PurchaseReady(
    context: context,
    quantity: quantity,
    validation: TicketQuantity.parse(quantity, alreadyHeld: context.alreadyHeld).errorOrNull,
  );

  Future<void> _onSubmitted(PurchaseSubmitted event, Emitter<PurchaseState> emit) async {
    final current = state;
    if (current is! PurchaseReady || current.validation != null || current.submitting) return;
    emit(current.copyWith(submitting: true));
    final Result<List<Ticket>> result;
    try {
      result = await reserveTickets(eventId: current.context.event.id, by: visitor, quantity: current.quantity);
    } on Exception catch (cause) {
      emit(PurchaseFailure(cause));
      return;
    }
    switch (result) {
      case Success(:final value):
        emit(PurchaseCompleted(value));
      case Failure(:final error):
        emit(current.copyWith(submitting: false, rejection: error));
    }
  }
}
