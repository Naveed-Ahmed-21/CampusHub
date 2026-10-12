import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/services/campus_download_service.dart';
import '../providers/dept_admin_provider.dart';

class DeptResourcesView extends ConsumerWidget {
  const DeptResourcesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(deptResourcesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Subject Resources',
        subtitle: 'Lecture Notes, Lab Manuals & Course Materials',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: resourcesAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading resources',
              message: err.toString(),
              onRetry: () => ref.refresh(deptResourcesProvider),
            ),
            data: (resources) {
              if (resources.isEmpty) {
                return const CampusEmptyState(
                  title: 'No Learning Resources Found',
                  description: 'No course materials uploaded yet.',
                  icon: Icons.folder_shared_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptResourcesProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final res = resources[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CampusGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.title,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${res.subjectName} • Uploaded by ${res.uploadedBy}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${res.fileType} • ${res.fileSize} • ${res.date}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_outlined, color: Colors.blue),
                              tooltip: 'Download Resource',
                              onPressed: () {
                                final ext = res.fileType.toLowerCase() == 'pdf' ? 'pdf' : 'bin';
                                final fileName = '${res.title.replaceAll(RegExp(r'\s+'), '_')}.$ext';
                                CampusDownloadService.downloadResource(
                                  context: context,
                                  fileUrl: res.fileUrl ?? '',
                                  fileName: fileName,
                                  subFolder: 'Department_Resources',
                                );
                              },
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
