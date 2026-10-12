import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/views/user_posts_view.dart';
import '../../../profile/presentation/views/user_follows_view.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_access_card.dart';
import '../widgets/admin_account_info_card.dart';
import '../widgets/admin_identity_card.dart';
import '../widgets/admin_profile_actions.dart';
import '../widgets/admin_profile_dialogs.dart';
import '../widgets/admin_profile_header.dart';
import '../widgets/admin_scope_card.dart';
import '../widgets/admin_security_card.dart';

class AdminProfileView extends ConsumerWidget {
  final bool isEmbedded;

  const AdminProfileView({
    super.key,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final profile = ref.watch(profileControllerProvider).value;
    final collegeAsync = ref.watch(adminCollegeSettingsProvider);

    final firstName = user?.firstName ?? profile?.firstName ?? '';
    final lastName = user?.lastName ?? profile?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? profile?.email ?? 'admin@gcee.ac.in';
    final role = user?.role ?? profile?.role ?? 'ADMIN';
    final isDeptAdmin = user?.isDeptAdmin == true || role == 'DEPT_ADMIN';
    final deptId = user?.departmentId ?? profile?.department;
    final status = user?.status ?? profile?.status ?? 'ACTIVE';
    final phone = user?.phone ?? profile?.phone;
    final avatarUrl = user?.avatarUrl ?? profile?.avatarUrl;
    final createdAt = user?.createdAt ?? profile?.createdAt;
    final updatedAt = user?.updatedAt ?? profile?.updatedAt;
    final lastSeen = user?.lastSeen ?? profile?.lastSeen;

    String collegeName = GceeBrand.institutionName;
    if (collegeAsync.hasValue && collegeAsync.value != null) {
      final fetched = collegeAsync.value!['name']?.toString();
      if (fetched != null && fetched.isNotEmpty) {
        collegeName = fetched;
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 840;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Profile Header (Full-width Hero)
        AdminProfileHeader(
          fullName: fullName,
          email: email,
          role: role,
          isDeptAdmin: isDeptAdmin,
          collegeName: collegeName,
          status: status,
          avatarUrl: avatarUrl,
          onEditProfile: () => AdminProfileDialogs.showEditProfile(
            context,
            ref,
            user: user,
            profile: profile,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        // 1b. Posts, Followers & Following Network Reach
        AdminNetworkStatsCard(
          profile: profile,
          userId: user?.id ?? profile?.id ?? '',
          fullName: fullName,
        ),
        const SizedBox(height: AppSpacing.s20),

        if (isDesktop) ...[
          // 2. Responsive Structured Two-Column Layout for Desktop
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Identity, Scope, Security
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminIdentityCard(
                      fullName: fullName,
                      email: email,
                      role: role,
                      isDeptAdmin: isDeptAdmin,
                      collegeName: collegeName,
                      phone: phone,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    AdminScopeCard(
                      isDeptAdmin: isDeptAdmin,
                      deptId: deptId,
                      collegeName: collegeName,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    AdminSecurityCard(
                      lastSeen: lastSeen,
                      onChangePassword: () => AdminProfileDialogs.showChangePassword(context, ref),
                      onManageSessions: () => AdminProfileDialogs.showActiveSessions(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s20),

              // Right Column: Access & Permissions, Account Info, Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminAccessCard(
                      isDeptAdmin: isDeptAdmin,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    AdminAccountInfoCard(
                      userId: user?.id ?? profile?.id ?? '',
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                      status: status,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    AdminProfileActions(
                      onViewActivity: () => context.push('/admin/activity'),
                      onSignOut: () => _handleSignOut(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // Mobile & Tablet Single-Column Layout
          AdminIdentityCard(
            fullName: fullName,
            email: email,
            role: role,
            isDeptAdmin: isDeptAdmin,
            collegeName: collegeName,
            phone: phone,
          ),
          const SizedBox(height: AppSpacing.s20),
          AdminScopeCard(
            isDeptAdmin: isDeptAdmin,
            deptId: deptId,
            collegeName: collegeName,
          ),
          const SizedBox(height: AppSpacing.s20),
          AdminAccessCard(
            isDeptAdmin: isDeptAdmin,
          ),
          const SizedBox(height: AppSpacing.s20),
          AdminSecurityCard(
            lastSeen: lastSeen,
            onChangePassword: () => AdminProfileDialogs.showChangePassword(context, ref),
            onManageSessions: () => AdminProfileDialogs.showActiveSessions(context),
          ),
          const SizedBox(height: AppSpacing.s20),
          AdminAccountInfoCard(
            userId: user?.id ?? profile?.id ?? '',
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
          ),
          const SizedBox(height: AppSpacing.s20),
          AdminProfileActions(
            onViewActivity: () => context.push('/admin/activity'),
            onSignOut: () => _handleSignOut(context, ref),
          ),
        ],
        const SizedBox(height: AppSpacing.s32),
        if (!isEmbedded) const CampusBottomNavSpacer(),
      ],
    );

    if (isEmbedded) {
      return content;
    }

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          title: 'Administrator Profile',
          leading: CampusBackButton.canPop(context)
              ? const CampusBackButton()
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => AdminProfileDialogs.showEditProfile(
                context,
                ref,
                user: user,
                profile: profile,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Profile',
              onPressed: () {
                ref.invalidate(adminCollegeSettingsProvider);
                ref.invalidate(authControllerProvider);
                ref.invalidate(profileControllerProvider);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out of CampusHub?'),
        content: const Text(
          'You will need to sign in again to access the administrator account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class AdminNetworkStatsCard extends StatelessWidget {
  final UserProfile? profile;
  final String userId;
  final String fullName;

  const AdminNetworkStatsCard({
    super.key,
    required this.profile,
    required this.userId,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posts = profile?.postsCount ?? 0;
    final followers = profile?.followersCount ?? 0;
    final following = profile?.followingCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatPillar(
              context,
              count: '$posts',
              label: 'Posts',
              icon: Icons.dynamic_feed_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const UserPostsView(initialTabIndex: 0),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _buildStatPillar(
              context,
              count: '$followers',
              label: 'Followers',
              icon: Icons.people_outline,
              onTap: () {
                if (userId.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => UserFollowsView(
                        userId: userId,
                        userName: fullName.isNotEmpty ? fullName : 'Administrator',
                        initialIndex: 0,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _buildStatPillar(
              context,
              count: '$following',
              label: 'Following',
              icon: Icons.person_add_alt_1_outlined,
              onTap: () {
                if (userId.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => UserFollowsView(
                        userId: userId,
                        userName: fullName.isNotEmpty ? fullName : 'Administrator',
                        initialIndex: 1,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPillar(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    count,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
