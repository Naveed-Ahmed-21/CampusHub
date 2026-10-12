import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/campus_glass_card.dart';

import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/profile_story_avatar.dart';

class AdminProfileHeader extends ConsumerWidget {
  final String fullName;
  final String email;
  final String role;
  final bool isDeptAdmin;
  final String collegeName;
  final String status;
  final String? avatarUrl;
  final VoidCallback onEditProfile;

  const AdminProfileHeader({
    super.key,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isDeptAdmin,
    required this.collegeName,
    required this.status,
    this.avatarUrl,
    required this.onEditProfile,
  });

  Future<void> _showAvatarOptionsSheet(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final resolvedAvatarUrl = hasAvatar ? ApiEndpoints.resolveUrl(avatarUrl!.trim()) : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Administrator Profile Photo',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (hasAvatar && resolvedAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: const Text('View Profile Photo'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  FullScreenImageViewer.openSingle(
                    context,
                    imageUrl: resolvedAvatarUrl,
                    heroTag: 'admin_profile_avatar_$fullName',
                    title: fullName,
                    subtitle: role,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo with Camera'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final file = await MediaPickerService.pickImageFromCamera();
                if (file != null && context.mounted) {
                  _uploadPhoto(context, ref, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final file = await MediaPickerService.pickImageFromGallery();
                if (file != null && context.mounted) {
                  _uploadPhoto(context, ref, file);
                }
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Current Photo', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Remove Profile Photo?'),
                      content: const Text(
                        'Are you sure you want to remove your administrator profile photo? Institutional initials will be displayed instead.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removing profile photo...')),
                      );
                      await ref.read(profileControllerProvider.notifier).removeAvatar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile photo removed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(BuildContext context, WidgetRef ref, SelectedMediaFile file) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading administrator photo...')),
      );

      final uploadService = ref.read(mediaUploadServiceProvider);
      final result = await uploadService.uploadSelectedFile(file);

      await ref.read(profileControllerProvider.notifier).uploadAvatar(result.url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrator profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = status.toUpperCase() == 'ACTIVE';

    final resolvedAvatarUrl = (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        ? ApiEndpoints.resolveUrl(avatarUrl!.trim())
        : null;

    return CampusGlassCard(
      intensity: GlassIntensity.strong,
      borderRadius: AppRadius.br24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          // 2. Interactive Profile Photo with Soft Blue Glass Glow & Edit Badge
          ProfileStoryAvatar(
            userId: ref.watch(authControllerProvider).asData?.value?.id ?? '',
            avatarUrl: avatarUrl,
            name: fullName,
            radius: 46,
            heroTag: 'admin_profile_avatar_$fullName',
            showCameraBadge: true,
            onCameraTap: () => _showAvatarOptionsSheet(context, ref),
            fallbackOnTap: () {
              if (resolvedAvatarUrl != null) {
                FullScreenImageViewer.openSingle(
                  context,
                  imageUrl: resolvedAvatarUrl,
                  heroTag: 'admin_profile_avatar_$fullName',
                  title: fullName,
                  subtitle: role,
                );
              } else {
                _showAvatarOptionsSheet(context, ref);
              }
            },
          ),

          const SizedBox(height: 14),

          // 3. Admin Real Name
          if (fullName.isNotEmpty) ...[
            Text(
              fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  'Profile incomplete',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: onEditProfile,
                  child: const Text('Complete Profile'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),

          // 4. Role Designation
          Text(
            isDeptAdmin ? 'Department Administrator' : 'Principal & Institutional Administrator',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),

          // 5. Institutional Name & Short Pill
          Text(
            collegeName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              GceeBrand.institutionShort,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6. Account Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Active Administrator' : status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 7. Edit Profile Action Button
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
