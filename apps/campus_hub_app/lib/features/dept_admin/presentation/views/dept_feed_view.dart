import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import 'dept_create_announcement_view.dart';

class DeptFeedView extends ConsumerWidget {
  const DeptFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Department Feed',
        subtitle: 'Official Notices & Circulars',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.electricBlue : AppColors.primaryBlue,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: const Text('New Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const DeptCreateAnnouncementView(),
          );
        },
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: feedAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading notices',
              message: err.toString(),
              onRetry: () => ref.read(feedControllerProvider.notifier).refreshFeed(),
            ),
            data: (posts) {
              return RefreshIndicator(
                onRefresh: () async => ref.read(feedControllerProvider.notifier).refreshFeed(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CampusGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'OFFICIAL CIRCULAR',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              post.title.isNotEmpty ? post.title : 'Department Notice',
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.content,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By: ${post.author.name.isNotEmpty ? post.author.name : 'Department HOD'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                                Text(
                                  'GCE Erode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
