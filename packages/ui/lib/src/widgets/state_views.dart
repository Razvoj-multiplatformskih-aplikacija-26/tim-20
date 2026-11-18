import 'package:flutter/material.dart';

import '../text/failures.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(label: 'Učitavanje', child: const CircularProgressIndicator()),
    );
  }
}

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.onRetry, this.cause});

  final VoidCallback onRetry;

  /// What stopped the data, so the screen can say that the server is down instead of a generic text.
  final Object? cause;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                failureMessage(cause),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            if (message case final message?) ...[
              const SizedBox(height: 8),
              Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
