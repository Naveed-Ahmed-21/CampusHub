import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/faculty_controller.dart';
import '../widgets/faculty_quick_actions_bar.dart';
import '../widgets/faculty_schedule_card.dart';
import '../widgets/faculty_drawer_widget.dart';

class FacultyHomeView extends ConsumerWidget {
  const FacultyHomeView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(facultyDashboardProvider);

    return Scaffold(
      drawer: const FacultyDrawerWidget(),
      appBar: CampusAppBar(
        title: GceeBrand.productName,
        subtitle: 'Faculty Hub',
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.search, size: 20),
            tooltip: 'Search Campus',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.notifications_outlined, size: 20),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            tooltip: 'Chats',
            onPressed: () => context.go('/chat'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AtmosphericBackground(
        child: ResponsiveLayout(
          mobile: _buildBody(context, ref, dashboardAsync, isDesktop: false),
          desktop: _buildBody(context, ref, dashboardAsync, isDesktop: true),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue dashboardAsync, {
    required bool isDesktop,
  }) {
    return AsyncValueWidget(
      value: dashboardAsync,
      data: (dashboard) {
        final content = CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 16.0,
                vertical: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome Header Card
                  _buildWelcomeCard(context, dashboard.faculty),
                  const SizedBox(height: 16),

                  // Quick Actions Bar
                  const FacultyQuickActionsBar(),
                  const SizedBox(height: 16),

                  // Today's Schedule Card
                  FacultyScheduleCard(slots: dashboard.todaySchedule),
                  const SizedBox(height: 16),

                  // KPI Metric Overview Badges
                  _buildKpiGrid(context, dashboard.stats),
                  const SizedBox(height: 16),
                  const CampusBottomNavSpacer(),
                ]),
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic faculty) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greeting = _getGreeting();

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      padding: AppSpacing.p20,
      child: Row(
        children: [
          CampusAvatar(
            imageUrl: faculty.avatarUrl,
            name: faculty.name,
            radius: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${faculty.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${faculty.designation} • ${faculty.department}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, dynamic stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: CampusStatCard(
                title: 'My Subjects',
                value: '${stats.totalSubjects}',
                icon: Icons.menu_book_outlined,
                accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                onTap: () => context.go('/teaching'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CampusStatCard(
                title: 'Mentees',
                value: '${stats.totalMentees}',
                icon: Icons.school_outlined,
                accentColor: AppColors.success,
                onTap: () => context.go('/teaching'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CampusStatCard(
                title: 'Classes Today',
                value: '${stats.todayClassesCount}',
                icon: Icons.schedule_outlined,
                accentColor: AppColors.warning,
                onTap: () => context.go('/teaching'),
              ),
            ),
          ],
        );
      },
    );
  }
}
