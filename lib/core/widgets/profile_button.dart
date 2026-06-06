import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';

class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pictureUrl =
        ref.watch(authControllerProvider).user?.profilePictureUrl ?? '';
    return IconButton.filledTonal(
      onPressed: () => context.push('/profile'),
      tooltip: 'Profile',
      icon: pictureUrl.isEmpty
          ? const Icon(Icons.person_rounded)
          : CircleAvatar(radius: 14, backgroundImage: NetworkImage(pictureUrl)),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .22),
        foregroundColor: Colors.white,
      ),
    );
  }
}
