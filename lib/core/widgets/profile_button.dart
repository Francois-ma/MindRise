import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => context.push('/profile'),
      tooltip: 'Profile',
      icon: const Icon(Icons.person_rounded),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .22),
        foregroundColor: Colors.white,
      ),
    );
  }
}
