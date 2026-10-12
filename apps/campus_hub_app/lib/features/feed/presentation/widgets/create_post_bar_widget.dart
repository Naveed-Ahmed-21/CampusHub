import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';
import '../../../../features/profile/presentation/providers/student_profile_provider.dart';

class CreatePostBarWidget extends ConsumerWidget {
  final VoidCallback onTap;

  const CreatePostBarWidget({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final detailed = ref.watch(studentDetailedProfileProvider).valueOrNull;
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    final resolvedName = detailed?.overview.fullName.isNotEmpty == true
        ? detailed!.overview.fullName
        : (profile != null && profile.fullName.isNotEmpty
            ? profile.fullName
            : (user != null ? '${user.firstName} ${user.lastName}'.trim() : ''));
    final greetingName = resolvedName.isNotEmpty
        ? resolvedName.split(' ').first
        : (user?.firstName.isNotEmpty == true ? user!.firstName : 'there');

    final avatarUrl = detailed?.overview.avatarUrl ?? profile?.avatarUrl ?? user?.avatarUrl;

    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          CampusAvatar(
            imageUrl: avatarUrl,
            name: greetingName,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  greetingName == 'there'
                      ? "What's on your mind?"
                      : "What's on your mind, $greetingName?",
                  style: TextStyle(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.image_outlined, color: iconColor, size: 22),
            onPressed: onTap,
            tooltip: 'Attach Image',
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: iconColor, size: 22),
            onPressed: onTap,
            tooltip: 'Camera',
          ),
        ],
      ),
    );
  }
}
