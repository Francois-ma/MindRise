import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 720 ? 1100.0 : 480.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF06110F),
                  Color(0xFF0B1A17),
                  Color(0xFF10211E),
                ],
                stops: [0, .56, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : AppColors.appBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
