import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../text.dart';
import '../widgets/quantity_stepper.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key, required this.id});

  final EventId id;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _setQuantity(int quantity) {
    _quantityController.text = '$quantity';
    context.read<PurchaseBloc>().add(PurchaseQuantityChanged(quantity));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) context.read<PurchaseBloc>().add(const PurchaseSubmitted());
  }

  void _onStateChanged(BuildContext context, PurchaseState state) {
    switch (state) {
      case PurchaseCompleted(:final tickets):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rezervisano je ${ticketsLabel(tickets.length)}. Platite u roku od ${reservationHold.inMinutes} minuta.',
            ),
          ),
        );
        context.read<MyTicketsBloc>().add(const MyTicketsRequested());
        context.read<EventsBloc>().add(const EventsRequested());
        context.go('/karte');
      case PurchaseLoading() || PurchaseFailure() || PurchaseNotFound() || PurchaseReady():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseBloc>();
    return BlocConsumer<PurchaseBloc, PurchaseState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Kupovina')),
          body: switch (state) {
            PurchaseLoading() || PurchaseCompleted() => const LoadingView(),
            PurchaseFailure() => FailureView(onRetry: () => bloc.add(PurchaseStarted(widget.id))),
            PurchaseNotFound() => const EmptyView(title: 'Događaj nije pronađen.'),
            PurchaseReady() => Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _PurchaseForm(
                state: state,
                quantityController: _quantityController,
                onQuantityChanged: _setQuantity,
              ),
            ),
          },
          bottomNavigationBar: state is! PurchaseReady
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: state.submitting ? null : _submit,
                    child: state.submitting
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Kupi'),
                  ),
                ),
        );
      },
    );
  }
}

class _PurchaseForm extends StatelessWidget {
  const _PurchaseForm({required this.state, required this.quantityController, required this.onQuantityChanged});

  final PurchaseReady state;
  final TextEditingController quantityController;
  final ValueChanged<int> onQuantityChanged;

  /// The form only asks the rule from the domain; the words come from the ui package.
  String? _validate(String? text) {
    final quantity = int.tryParse(text ?? '');
    if (quantity == null) return 'Unesite broj karata.';
    return switch (TicketQuantity.parse(quantity, alreadyHeld: state.context.alreadyHeld)) {
      Success() => null,
      Failure(:final error) => error.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final event = state.context.event;
    final rejection = state.rejection;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Semantics(header: true, child: Text(event.name, style: theme.textTheme.headlineMedium)),
        const SizedBox(height: 4),
        Text('${formatDateTime(event.startsAt)} · ${event.venue}', style: muted),
        const SizedBox(height: 4),
        Text('${priceLabel(event.priceRsd)} po karti · ${remainingLabel(state.context.remaining)}', style: muted),
        if (state.context.alreadyHeld > 0) ...[
          const SizedBox(height: 4),
          Text('Na ovom događaju imate ${ticketsLabel(state.context.alreadyHeld)}.', style: muted),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExcludeSemantics(child: Text('Broj karata', style: theme.textTheme.titleMedium)),
                QuantityStepper(value: state.quantity, onChanged: state.submitting ? (_) {} : onQuantityChanged),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: quantityController,
          enabled: !state.submitting,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Broj karata',
            helperText: 'Najviše ${ticketsLabel(TicketQuantity.max)} po događaju.',
          ),
          validator: _validate,
          onChanged: (text) {
            final quantity = int.tryParse(text);
            if (quantity != null) context.read<PurchaseBloc>().add(PurchaseQuantityChanged(quantity));
          },
        ),
        if (rejection != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(rejection.message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error)),
          ),
        ],
      ],
    );
  }
}
