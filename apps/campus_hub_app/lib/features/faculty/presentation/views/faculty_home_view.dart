import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/feed_post_card_widget.dart';
import '../controllers/faculty_controller.dart';
import '../widgets/faculty_quick_actions_bar.dart';
import '../widgets/faculty_schedule_card.dart';

class FacultyHomeView extends ConsumerWidget {
  const FacultyHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(facultyDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'CampusHub Faculty',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Campus',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chats',
            onPressed: () => context.go('/chat'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, ref, dashboardAsync, isDesktop: false),
        desktop: _buildBody(context, ref, dashboardAsync, isDesktop: true),
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
                  const SizedBox(height: 20),

                  // Section Header: Department & Campus Feed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic & Department Stream',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/faculty/campus'),
                        icon: const Icon(Icons.hub, size: 16),
                        label: const Text('Campus Ecosystem'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
            // Seamless Stream Posts (co-scrollable with dashboard)
            ref.watch(feedControllerProvider).when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No recent academic stream posts.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32.0 : 16.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = posts[index];
                            return FeedPostCardWidget(
                              post: post,
                              onOpenComments: () {},
                            );
                          },
                          childCount: posts.length > 5 ? 5 : posts.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.blue.shade800, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: faculty.avatarUrl != null
                ? NetworkImage(faculty.avatarUrl!)
                : null,
            child: faculty.avatarUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${faculty.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${faculty.designation} • ${faculty.department}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
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
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            title: 'Subjects Handled',
            value: '${stats.totalSubjects}',
            icon: Icons.menu_book,
            color: Colors.blue,
            onTap: () => context.go('/teaching'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
            title: 'Assigned Mentees',
            value: '${stats.totalMentees}',
            icon: Icons.school,
            color: Colors.teal,
            onTap: () => context.go('/teaching'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
            title: 'Today Classes',
            value: '${stats.todayClassesCount}',
            icon: Icons.access_time_filled,
            color: Colors.orange,
            onTap: () => context.go('/teaching'),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
