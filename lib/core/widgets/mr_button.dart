import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MRButton extends StatelessWidget {
  const MRButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppColors.primaryGradient,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled
            ? null
            : Theme.of(context).disabledColor.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: .22),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        icon: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}
