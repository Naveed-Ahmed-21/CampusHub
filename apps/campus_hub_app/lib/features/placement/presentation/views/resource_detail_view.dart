import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/services/campus_download_service.dart';
import '../providers/placement_provider.dart';

class ResourceDetailView extends ConsumerWidget {
  final String resourceId;

  const ResourceDetailView({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resAsync = ref.watch(resourceDetailsProvider(resourceId));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: resAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              message: 'Failed to load preparation resource',
              onRetry: () => ref.refresh(resourceDetailsProvider(resourceId)),
            ),
            data: (res) {
              final isPdf = res.resourceType == 'PDF';
              final isVideo = res.resourceType == 'VIDEO' || res.resourceType == 'YOUTUBE_PLAYLIST';
              final isTest = res.resourceType == 'MOCK_TEST';

              IconData formatIcon = Icons.description;
              Color formatColor = const Color(0xFFEF4444); // PDF red
              if (isVideo) {
                formatIcon = Icons.play_circle_filled;
                formatColor = const Color(0xFFEF4444);
              } else if (isTest) {
                formatIcon = Icons.quiz;
                formatColor = const Color(0xFF8B5CF6);
              } else if (res.resourceType == 'EXTERNAL_LINK') {
                formatIcon = Icons.language;
                formatColor = AppColors.primaryBlue;
              }

              final openUrl = res.externalUrl ?? res.fileUrl;

              return Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const CampusBackButton(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resource Details',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Resource link copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Big Format Card (Image 14)
                        CampusGlassCard(
                          intensity: GlassIntensity.medium,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: formatColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(formatIcon, color: formatColor, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${res.category} • ${res.resourceType}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                res.title,
                                style: AppTypography.pageTitle.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploaded by ${res.creatorName ?? 'Placement Cell'} • ${res.viewsCount} Views',
                                style: AppTypography.micro.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description Section (Image 14)
                        Text(
                          'Overview & Description',
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CampusGlassCard(
                          intensity: GlassIntensity.medium,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            (res.description != null && res.description!.trim().isNotEmpty)
                                ? res.description!
                                : 'No detailed description provided for this resource.',
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Topics Covered Tags
                        Text(
                          'Topics & Curriculum',
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (res.tags.isNotEmpty ? res.tags : ['Aptitude', 'Data Structures', 'Logical Reasoning', 'Interview Prep'])
                              .map((tag) {
                            return Chip(
                              label: Text(tag, style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600)),
                              backgroundColor: isDark
                                  ? AppColors.darkSurface.withValues(alpha: 0.8)
                                  : Colors.white,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons (Download to Device & Open Link)
                        if (res.fileUrl != null && res.fileUrl!.trim().isNotEmpty) ...[
                          CampusButton(
                            label: 'Download to Device Storage',
                            icon: const Icon(Icons.download_rounded),
                            type: CampusButtonType.primary,
                            onPressed: () {
                              final ext = isPdf ? 'pdf' : (isVideo ? 'mp4' : 'bin');
                              final fileName = '${res.title.replaceAll(RegExp(r'\s+'), '_')}.$ext';
                              CampusDownloadService.downloadResource(
                                context: context,
                                fileUrl: res.fileUrl!,
                                fileName: fileName,
                                subFolder: 'Placement_Preparation',
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (openUrl != null && openUrl.isNotEmpty) ...[
                          CampusButton(
                            label: isTest ? 'Start Mock Assessment' : (isPdf ? 'Open in Browser' : 'Open Resource Link'),
                            icon: Icon(isTest ? Icons.play_arrow : Icons.launch),
                            type: res.fileUrl != null && res.fileUrl!.trim().isNotEmpty
                                ? CampusButtonType.outline
                                : CampusButtonType.primary,
                            onPressed: () {
                              launchUrlString(openUrl, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
