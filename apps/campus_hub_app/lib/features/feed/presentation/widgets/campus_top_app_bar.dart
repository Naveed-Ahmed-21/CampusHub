import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';
import '../../../../features/profile/presentation/providers/student_profile_provider.dart';
import 'create_post_sheet.dart';

class CampusTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;

  const CampusTopAppBar({
    super.key,
    required this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final detailed = ref.watch(studentDetailedProfileProvider).value;
    final profile = ref.watch(profileControllerProvider).value;

    final resolvedName = detailed?.overview.fullName.isNotEmpty == true
        ? detailed!.overview.fullName
        : (profile != null && profile.fullName.isNotEmpty
            ? profile.fullName
            : (user != null ? '${user.firstName} ${user.lastName}'.trim() : ''));
    final headerName = resolvedName.isNotEmpty ? resolvedName : (user?.firstName ?? '');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    final unreadChats = ref.watch(unreadChatsCountProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final surfaceColor = isDark
        ? AppColors.darkAppBarSurface
        : AppColors.lightAppBarSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassTheme.blurMedium,
            sigmaY: AppGlassTheme.blurMedium,
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu_rounded, size: 24, color: primary),
                    tooltip: 'Navigation Menu',
                    onPressed: onOpenDrawer,
                  ),
                  const SizedBox(width: 4),

                  // GCEE Institutional Logo
                  const GceeLogo.header(),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              GceeBrand.productName,
                              style: AppTypography.cardTitle.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.border,
                                ),
                              ),
                              child: Text(
                                GceeBrand.institutionShort,
                                style: AppTypography.micro.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          headerName.isNotEmpty
                              ? '$headerName • ${GceeBrand.institutionName}'
                              : GceeBrand.institutionName,
                          style: AppTypography.micro.copyWith(
                            color: secondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  IconButton(
                    icon: Icon(Icons.add_box_outlined, size: 22, color: primary),
                    tooltip: 'New Post',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const CreatePostSheet(),
                      );
                    },
                  ),

                  // Notification Bell (Replacing generic heart)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, size: 23, color: primary),
                        tooltip: 'Notifications',
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadNotifications',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Chat Action
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat_bubble_outline_rounded, size: 21, color: primary),
                        tooltip: 'Chats',
                        onPressed: () => context.push('/chat'),
                      ),
                      if (unreadChats > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadChats',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
