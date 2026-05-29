import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../data/learning_repository.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);
    final articles = ref.watch(articlesProvider);
    final materials = ref.watch(learningMaterialsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoriesProvider);
        ref.invalidate(articlesProvider);
        ref.invalidate(learningMaterialsProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                const GradientHeader(
                  title: 'Mind Library',
                  subtitle: 'Clinically reviewed education for everyday care.',
                  icon: Icons.menu_book_rounded,
                  gradient: LinearGradient(
                    colors: [AppColors.lime, AppColors.emerald],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  trailing: ProfileButton(),
                ),
                const SizedBox(height: AppSpacing.xl),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search mental health topics...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const MRCard(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF7D6), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, color: AppColors.amber),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Try one small action after reading: breathe, journal, or ask for support.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Explore Topics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                categories.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No topics published yet.');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in items)
                          ActionChip(
                            label: Text(category.name),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Showing ${category.name} resources soon.',
                                  ),
                                ),
                              );
                            },
                            backgroundColor: AppColors.emerald.withValues(
                              alpha: .10,
                            ),
                            labelStyle: const TextStyle(
                              color: AppColors.emerald,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const InlineLoadingCard(message: 'Loading topics...'),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Uploaded Materials',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                materials.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const MRCard(
                        child: Text('No learning materials published yet.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final material in items) ...[
                          _LearningMaterialTile(material: material),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const InlineLoadingCard(message: 'Loading materials...'),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(learningMaterialsProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Featured Articles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                articles.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const MRCard(
                        child: Text('No articles published yet.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final article in items) ...[
                          _ArticleTile(article: article),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const InlineLoadingCard(message: 'Loading articles...'),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(articlesProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningMaterialTile extends StatelessWidget {
  const _LearningMaterialTile({required this.material});

  final LearningMaterial material;

  Future<void> _openMaterial(BuildContext context) async {
    if (!material.hasUrl) return;
    final uri = Uri.tryParse(material.url);
    final canOpen =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    if (!canOpen) {
      await _copyLink(context, 'Material link copied.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        await _copyLink(context, 'Could not open it, so the link was copied.');
      }
    } on Object {
      if (context.mounted) {
        await _copyLink(context, 'Could not open it, so the link was copied.');
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String message) async {
    await Clipboard.setData(ClipboardData(text: material.url));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (material.type) {
      LearningMaterialType.audio => Icons.headphones_rounded,
      LearningMaterialType.video => Icons.play_circle_rounded,
      LearningMaterialType.slides => Icons.co_present_rounded,
      LearningMaterialType.worksheet => Icons.edit_note_rounded,
      LearningMaterialType.link => Icons.link_rounded,
      LearningMaterialType.pdf ||
      LearningMaterialType.unknown => Icons.picture_as_pdf_rounded,
    };
    final accent = switch (material.type) {
      LearningMaterialType.audio => AppColors.blue,
      LearningMaterialType.video => AppColors.rose,
      LearningMaterialType.slides => AppColors.lavender,
      LearningMaterialType.worksheet => AppColors.emerald,
      LearningMaterialType.link => AppColors.cyan,
      LearningMaterialType.pdf ||
      LearningMaterialType.unknown => AppColors.amber,
    };

    return MRCard(
      padding: const EdgeInsets.all(18),
      onTap: material.hasUrl ? () => _openMaterial(context) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (material.summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    material.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(icon, size: 14, color: accent),
                      label: Text(material.type.label),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (material.category.isNotEmpty)
                      Chip(
                        label: Text(material.category),
                        visualDensity: VisualDensity.compact,
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${material.estimatedMinutes} min',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    if (material.fileSizeLabel.isNotEmpty)
                      Text(
                        material.fileSizeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: material.hasUrl ? () => _openMaterial(context) : null,
            tooltip: material.hasUrl ? 'Open material' : 'No link yet',
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
    );
  }
}

class _ArticleTile extends ConsumerWidget {
  const _ArticleTile({required this.article});

  final Article article;

  Future<void> _bookmark(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(learningRepositoryProvider).bookmarkArticle(article.id);
      ref.invalidate(articlesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Article saved.')));
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return MRCard(
      padding: const EdgeInsets.all(18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article reading view is coming soon.')),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (article.summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (article.category.isNotEmpty)
                      Chip(
                        label: Text(article.category),
                        visualDensity: VisualDensity.compact,
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${article.readTimeMinutes} min',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: article.isBookmarked
                ? null
                : () => _bookmark(context, ref),
            tooltip: article.isBookmarked ? 'Saved' : 'Save article',
            icon: Icon(
              article.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
