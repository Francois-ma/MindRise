import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../utils/api_error.dart';
import 'mr_card.dart';

class InlineLoadingCard extends StatelessWidget {
  const InlineLoadingCard({this.message = 'Loading...', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
    );
  }
}

class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({
    required this.error,
    required this.onRetry,
    this.title = 'Could not load data',
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            userMessageFromError(error),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class AsyncSliverBox<T> extends StatelessWidget {
  const AsyncSliverBox({
    required this.value,
    required this.builder,
    required this.onRetry,
    this.loadingMessage = 'Loading...',
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: value.when(
        data: builder,
        loading: () => InlineLoadingCard(message: loadingMessage),
        error: (error, stackTrace) =>
            InlineErrorCard(error: error, onRetry: onRetry),
      ),
    );
  }
}
