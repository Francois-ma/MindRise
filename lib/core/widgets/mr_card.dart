import 'package:flutter/material.dart';

class MRCard extends StatelessWidget {
  const MRCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .18)
                : const Color(0xFF163A34).withValues(alpha: .07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: gradient == null
            ? (isDark ? theme.colorScheme.surfaceContainer : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: onTap == null ? 1 : 1,
      duration: const Duration(milliseconds: 160),
      child: card,
    );
  }
}
