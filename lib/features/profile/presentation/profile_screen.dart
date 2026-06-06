import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mood/data/mood_repository.dart';
import '../../support/data/support_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isPractitioner = user?.role == AppUserRole.practitioner;
    final summary = ref.watch(moodSummaryProvider);
    final practitioners = isPractitioner
        ? ref.watch(practitionersProvider)
        : null;
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList.list(
                children: [
                  GradientHeader(
                    title: user?.name ?? 'MindRise member',
                    subtitle: user?.email ?? 'Authenticated account',
                    icon: Icons.verified_user_rounded,
                    leading: IconButton(
                      onPressed: () => context.go('/home'),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AccountStatusCard(user: user),
                  const SizedBox(height: AppSpacing.xl),
                  if (isPractitioner) ...[
                    _PractitionerAccessCard(user: user),
                    const SizedBox(height: AppSpacing.xl),
                    practitioners!.when(
                      data: (items) {
                        Practitioner? profile;
                        for (final item in items) {
                          if (item.isMyProfile) profile = item;
                        }
                        return _ProfessionalProfileCard(
                          profile: profile,
                          onEdit: profile == null
                              ? null
                              : () => _showEditProfessionalProfileDialog(
                                  context,
                                  ref,
                                  profile!,
                                ),
                        );
                      },
                      loading: () => const InlineLoadingCard(
                        message: 'Loading professional profile...',
                      ),
                      error: (error, stackTrace) => InlineErrorCard(
                        error: error,
                        onRetry: () => ref.invalidate(practitionersProvider),
                      ),
                    ),
                  ] else
                    summary.when(
                      data: (data) => _WellnessStats(summary: data),
                      loading: () => const InlineLoadingCard(
                        message: 'Loading your wellness record...',
                      ),
                      error: (error, stackTrace) => InlineErrorCard(
                        title: 'Wellness record unavailable',
                        error: error,
                        onRetry: () => ref.invalidate(moodSummaryProvider),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _AccountSection(
                    title: 'Account Access',
                    children: [
                      _AccountRow(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        value: user?.email ?? 'Not available',
                      ),
                      _AccountRow(
                        icon: Icons.badge_rounded,
                        label: 'Role',
                        value: _roleLabel(user?.role),
                      ),
                      _AccountRow(
                        icon: Icons.verified_rounded,
                        label: 'Verification',
                        value: user?.isEmailVerified == true
                            ? 'Verified'
                            : 'Verification required',
                        valueColor: user?.isEmailVerified == true
                            ? AppColors.emerald
                            : theme.colorScheme.error,
                      ),
                      _AccountRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: user?.phoneNumber.isNotEmpty == true
                            ? user!.phoneNumber
                            : 'Not added',
                      ),
                      _AccountRow(
                        icon: Icons.public_rounded,
                        label: 'Timezone',
                        value: user?.timezone ?? 'UTC',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileActions(user: user),
                  const SizedBox(height: AppSpacing.xl),
                  const _PrivacyCard(),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MindRise v1.0.0',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: user == null
                ? null
                : () => _showEditProfileDialog(context, user!),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPasswordDialog(context),
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Password'),
          ),
        ),
      ],
    );
  }
}

Future<void> _showEditProfileDialog(BuildContext context, AppUser user) async {
  final firstNameController = TextEditingController(text: user.firstName);
  final lastNameController = TextEditingController(text: user.lastName);
  final phoneController = TextEditingController(text: user.phoneNumber);
  final dateOfBirthController = TextEditingController(text: user.dateOfBirth);
  final timezoneController = TextEditingController(text: user.timezone);
  final formKey = GlobalKey<FormState>();
  XFile? selectedPicture;
  var removeProfilePicture = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var isSaving = false;
      return Consumer(
        builder: (context, ref, child) {
          return StatefulBuilder(
            builder: (context, setState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate() || isSaving) return;
                setState(() => isSaving = true);
                final success = await ref
                    .read(authControllerProvider.notifier)
                    .updateProfile(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      phoneNumber: phoneController.text,
                      dateOfBirth: dateOfBirthController.text,
                      timezone: timezoneController.text,
                      profilePicturePath: selectedPicture?.path,
                      removeProfilePicture: removeProfilePicture,
                    );
                if (!context.mounted) return;
                setState(() => isSaving = false);
                if (success) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated securely.')),
                  );
                } else {
                  final message = ref.read(authControllerProvider).errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message ?? 'Profile update failed.'),
                    ),
                  );
                }
              }

              return AlertDialog(
                title: const Text('Edit profile'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.emerald.withValues(
                                alpha: .12,
                              ),
                              backgroundImage: selectedPicture != null
                                  ? FileImage(File(selectedPicture!.path))
                                  : !removeProfilePicture &&
                                        user.profilePictureUrl.isNotEmpty
                                  ? NetworkImage(user.profilePictureUrl)
                                  : null,
                              child:
                                  selectedPicture == null &&
                                      (removeProfilePicture ||
                                          user.profilePictureUrl.isEmpty)
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.emerald,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            final picture = await ImagePicker()
                                                .pickImage(
                                                  source: ImageSource.gallery,
                                                  maxWidth: 1200,
                                                  imageQuality: 88,
                                                );
                                            if (picture != null) {
                                              setState(() {
                                                selectedPicture = picture;
                                                removeProfilePicture = false;
                                              });
                                            }
                                          },
                                    icon: const Icon(Icons.add_a_photo_rounded),
                                    label: Text(
                                      user.profilePictureUrl.isEmpty
                                          ? 'Add photo'
                                          : 'Replace photo',
                                    ),
                                  ),
                                  if (user.profilePictureUrl.isNotEmpty ||
                                      selectedPicture != null)
                                    TextButton(
                                      onPressed: isSaving
                                          ? null
                                          : () => setState(() {
                                              selectedPicture = null;
                                              removeProfilePicture = true;
                                            }),
                                      child: const Text('Remove photo'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'First name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: dateOfBirthController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Date of birth',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.cake_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: timezoneController,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            prefixIcon: Icon(Icons.public_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );

  firstNameController.dispose();
  lastNameController.dispose();
  phoneController.dispose();
  dateOfBirthController.dispose();
  timezoneController.dispose();
}

Future<void> _showEditProfessionalProfileDialog(
  BuildContext context,
  WidgetRef ref,
  Practitioner profile,
) async {
  final displayNameController = TextEditingController(
    text: profile.displayName,
  );
  final specializationController = TextEditingController(
    text: profile.specialization,
  );
  final bioController = TextEditingController(text: profile.bio);
  final phoneController = TextEditingController(text: profile.phoneNumber);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var isSaving = false;
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate() || isSaving) return;
            setState(() => isSaving = true);
            try {
              await ref
                  .read(supportRepositoryProvider)
                  .updateProfessionalProfile(
                    displayName: displayNameController.text,
                    specialization: specializationController.text,
                    bio: bioController.text,
                    phoneNumber: phoneController.text,
                  );
              ref.invalidate(practitionersProvider);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Professional profile updated.'),
                  ),
                );
              }
            } on Object catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
              setState(() => isSaving = false);
            }
          }

          return AlertDialog(
            title: const Text('Edit professional profile'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Display name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.psychology_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: bioController,
                      maxLength: 1200,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Professional bio',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Call and WhatsApp number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : save,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  displayNameController.dispose();
  specializationController.dispose();
  bioController.dispose();
  phoneController.dispose();
}

Future<void> _showPasswordDialog(BuildContext context) async {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var isSaving = false;
      var obscurePassword = true;
      return Consumer(
        builder: (context, ref, child) {
          return StatefulBuilder(
            builder: (context, setState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate() || isSaving) return;
                setState(() => isSaving = true);
                final success = await ref
                    .read(authControllerProvider.notifier)
                    .changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                if (!context.mounted) return;
                setState(() => isSaving = false);
                if (success) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed securely.')),
                  );
                } else {
                  final message = ref.read(authControllerProvider).errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message ?? 'Password change failed.'),
                    ),
                  );
                }
              }

              return AlertDialog(
                title: const Text('Change password'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentController,
                        obscureText: obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                          prefixIcon: Icon(Icons.lock_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your current password'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: newController,
                        obscureText: obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (value) => value == null || value.length < 10
                            ? 'Use at least 10 characters'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: const Icon(Icons.verified_user_rounded),
                          suffixIcon: IconButton(
                            tooltip: obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        validator: (value) => value != newController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset_rounded),
                    label: const Text('Update'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );

  currentController.dispose();
  newController.dispose();
  confirmController.dispose();
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = user?.isEmailVerified == true;

    return MRCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: verified
                ? AppColors.emerald
                : theme.colorScheme.errorContainer,
            backgroundImage: user?.profilePictureUrl.isNotEmpty == true
                ? NetworkImage(user!.profilePictureUrl)
                : null,
            child: user?.profilePictureUrl.isNotEmpty == true
                ? null
                : Icon(
                    verified ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: verified
                        ? Colors.white
                        : theme.colorScheme.onErrorContainer,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Secure account' : 'Verification required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verified
                      ? 'Your MindRise account is authorized for private wellness features.'
                      : 'Verify your email before using private wellness features.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: Icons.verified_user_rounded,
                      label: verified ? 'Verified' : 'Pending',
                      color: verified
                          ? AppColors.emerald
                          : theme.colorScheme.error,
                    ),
                    _StatusChip(
                      icon: Icons.badge_rounded,
                      label: _roleLabel(user?.role),
                      color: AppColors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PractitionerAccessCard extends StatelessWidget {
  const _PractitionerAccessCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFE8FFF5), Color(0xFFE8F9FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.teal),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Practitioner access',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user?.isApproved == true
                ? 'Your practitioner account is approved. Use the practitioner workspace to manage availability and patient conversations.'
                : 'Your practitioner account is waiting for approval.',
          ),
        ],
      ),
    );
  }
}

class _ProfessionalProfileCard extends StatelessWidget {
  const _ProfessionalProfileCard({required this.profile, required this.onEdit});
  final Practitioner? profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.emerald.withValues(alpha: .14),
                backgroundImage: profile?.profilePictureUrl.isNotEmpty == true
                    ? NetworkImage(profile!.profilePictureUrl)
                    : null,
                child: profile?.profilePictureUrl.isNotEmpty == true
                    ? null
                    : const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.emerald,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? 'Professional profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      profile?.specialization.isNotEmpty == true
                          ? profile!.specialization
                          : 'Add your specialization',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onEdit,
                tooltip: 'Edit professional profile',
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          if (profile?.bio.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(profile!.bio),
          ],
        ],
      ),
    );
  }
}

class _WellnessStats extends StatelessWidget {
  const _WellnessStats({required this.summary});

  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileStat(
            label: 'Average',
            value: summary.averageScore == 0
                ? '--'
                : summary.averageScore.toStringAsFixed(1),
            icon: Icons.monitor_heart_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            label: 'Entries',
            value: summary.totalEntries.toString(),
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            label: 'Top mood',
            value: _formatMood(summary.mostFrequentMood),
            icon: Icons.psychology_alt_rounded,
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.emerald),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        MRCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primaryContainer.withValues(alpha: .72),
          theme.colorScheme.surfaceContainerLow,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by design',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your wellness records are loaded only after sign-in and are tied to your secure MindRise account.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _roleLabel(AppUserRole? role) {
  return switch (role) {
    AppUserRole.patient => 'Member',
    AppUserRole.practitioner => 'Practitioner',
    AppUserRole.admin => 'Administrator',
    AppUserRole.unknown || null => 'Member',
  };
}

String _formatMood(String? mood) {
  if (mood == null || mood.trim().isEmpty) return '--';
  return mood
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
