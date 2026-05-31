import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = AppColors.primaryGradient,
    this.trailing,
    this.leading,
    this.largeTitle = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Widget? trailing;
  final Widget? leading;
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (leading != null) Positioned(left: 0, top: 0, child: leading!),
          if (trailing != null) Positioned(right: 0, top: 0, child: trailing!),
          Padding(
            padding: EdgeInsets.only(
              top: leading == null && trailing == null ? 0 : 36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .20),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: largeTitle ? 28 : null,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .86),
                    height: 1.35,
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
