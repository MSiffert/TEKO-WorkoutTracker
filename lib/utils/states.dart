
import 'package:flutter/material.dart';

class LoadingBlock extends StatelessWidget {
  final String message;
  const LoadingBlock({super.key, this.message = 'Lade...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBlock({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Neu laden'))
            ]
          ],
        ),
      ),
    );
  }
}

class EmptyBlock extends StatelessWidget {
  final String title;
  final String? detail;
  final Widget? action;
  const EmptyBlock({super.key, required this.title, this.detail, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 48),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ]
          ],
        ),
      ),
    );
  }
}