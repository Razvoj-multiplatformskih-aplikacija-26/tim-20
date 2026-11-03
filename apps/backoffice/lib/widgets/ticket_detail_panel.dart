import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class TicketDetailPanel extends StatelessWidget {
  const TicketDetailPanel({
    super.key,
    required this.ticket,
    required this.actions,
    required this.busy,
    required this.onConfirm,
    required this.onAdmit,
    required this.onVoid,
    required this.onClose,
  });

  final Ticket ticket;
  final Set<StaffAction> actions;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onAdmit;
  final VoidCallback onVoid;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final status = ticket.status;
    final statusDetail = switch (status) {
      Reserved(:final expiresAt) => 'Rok za plaćanje ističe ${formatDateTime(expiresAt)}.',
      Paid(:final paidAt, :final confirmedBy) =>
        'Plaćena ${formatDateTime(paidAt)}${confirmedBy == null ? '.' : ', potvrdio organizator.'}',
      Used(:final scannedAt) => 'Ušao ${formatDateTime(scannedAt)}.',
      Cancelled(:final at, :final reason) => 'Otkazana ${formatDateTime(at)}.${reason.isEmpty ? '' : ' $reason'}',
      Expired(:final at) => 'Istekla ${formatDateTime(at)}, nije plaćena na vreme.',
    };
    return Semantics(
      container: true,
      label: 'Detalj karte',
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(ticket.holderName, style: theme.textTheme.headlineSmall),
                    ),
                  ),
                  IconButton(tooltip: 'Zatvori detalj (Esc)', onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    Align(alignment: Alignment.centerLeft, child: StatusBadge(status)),
                    const SizedBox(height: 8),
                    Text(statusDetail, style: muted),
                    const SizedBox(height: 20),
                    _Field(label: 'Kôd', value: ticket.code),
                    _Field(label: 'Kupljeno', value: formatDateTime(ticket.createdAt)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (actions.contains(StaffAction.confirmPayment))
                    _ActionButton(
                      label: 'Potvrdi plaćanje',
                      shortcut: 'C',
                      icon: Icons.check,
                      onPressed: busy ? null : onConfirm,
                    ),
                  if (actions.contains(StaffAction.admit))
                    _ActionButton(
                      label: 'Pusti na ulaz',
                      shortcut: 'U',
                      icon: Icons.login,
                      onPressed: busy ? null : onAdmit,
                    ),
                  if (actions.contains(StaffAction.voidTicket)) ...[
                    const SizedBox(height: 8),
                    _ActionButton(
                      label: 'Poništi',
                      shortcut: 'X',
                      icon: Icons.block,
                      onPressed: busy ? null : onVoid,
                      tonal: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.shortcut,
    required this.icon,
    required this.onPressed,
    this.tonal = false,
  });

  final String label;
  final String shortcut;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
    return Tooltip(
      message: '$label ($shortcut)',
      child: tonal
          ? FilledButton.tonal(onPressed: onPressed, child: child)
          : FilledButton(onPressed: onPressed, child: child),
    );
  }
}
