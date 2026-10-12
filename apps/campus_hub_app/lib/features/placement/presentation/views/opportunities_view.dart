import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_status_badge.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../providers/placement_provider.dart';
import '../../domain/placement_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class OpportunitiesView extends ConsumerStatefulWidget {
  const OpportunitiesView({super.key});

  @override
  ConsumerState<OpportunitiesView> createState() => _OpportunitiesViewState();
}

class _OpportunitiesViewState extends ConsumerState<OpportunitiesView> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _statusFilters = ['ALL', 'ONGOING', 'UPCOMING', 'COMPLETED'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final isOfficer = user?.isPlacementOfficer == true || user?.isAdmin == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final drivesAsync = ref.watch(placementDrivesByStatusProvider(_selectedStatus));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CampusBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Placement Drives',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Explore campus recruitment opportunities',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOfficer)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        tooltip: 'Post New Drive',
                        onPressed: () => context.push('/placement/create-drive'),
                      ),
                  ],
                ),
              ),

              // Blueprint Image 04: Segmented Navigation Pills (Drives, Companies, Applications)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work, size: 15, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Drives',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/placement/companies'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 15,
                                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Companies',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/placement/applications'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 15,
                                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Applications',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      hintText: 'Search by company, role or location...',
                      hintStyle: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _statusFilters.map((status) {
                    final isSelected = _selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          status == 'ALL' ? 'All Drives' : status,
                          style: AppTypography.captionMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkText : AppColors.primaryText),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        selectedColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                        backgroundColor: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.6),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatus = status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),


              // Drives List
              Expanded(
                child: drivesAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load placement drives',
                    onRetry: () => ref.refresh(placementDrivesByStatusProvider(_selectedStatus)),
                  ),
                  data: (drives) {
                    final filtered = drives.where((d) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      return d.companyName.toLowerCase().contains(q) ||
                          d.roleTitle.toLowerCase().contains(q) ||
                          (d.location?.toLowerCase().contains(q) ?? false);
                    }).toList();

                    if (filtered.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Placement Drives Found',
                        description: _searchQuery.isEmpty
                            ? 'There are currently no placement drives in this category.'
                            : 'No drives match your search query "$_searchQuery".',
                        icon: Icons.work_off_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(placementDrivesByStatusProvider(_selectedStatus)),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final drive = filtered[index];
                          return _buildDriveCard(context, drive, isDark, isOfficer);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isOfficer
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/placement/create-drive'),
              backgroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post Drive', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildDriveCard(
    BuildContext context,
    PlacementDriveModel drive,
    bool isDark,
    bool isOfficer,
  ) {
    StatusBadgeType badgeType;
    if (drive.status == 'ONGOING') {
      badgeType = StatusBadgeType.success;
    } else if (drive.status == 'UPCOMING') {
      badgeType = StatusBadgeType.info;
    } else {
      badgeType = StatusBadgeType.neutral;
    }

    final daysLeft = drive.deadline.difference(DateTime.now()).inDays;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final deadlineDateStr = '${drive.deadline.day} ${months[drive.deadline.month - 1]} ${drive.deadline.year}';

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      onTap: () => context.push('/placement/drives/${drive.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Company & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real Company Logo or fallback
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: drive.companyLogo != null && drive.companyLogo!.isNotEmpty
                    ? Image.network(
                        drive.companyLogo!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackInitial(drive.companyName, isDark),
                      )
                    : _buildFallbackInitial(drive.companyName, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drive.companyName,
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      drive.roleTitle,
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CampusStatusBadge(
                label: drive.status,
                type: badgeType,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Details Pills (CTC, Location, Branches/Batch, CGPA)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (drive.packageCtc != null)
                _buildTag(
                  icon: Icons.payments_outlined,
                  text: drive.packageCtc!,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                  isDark: isDark,
                ),
              if (drive.allowedDepartments.isNotEmpty)
                _buildTag(
                  icon: Icons.school_outlined,
                  text: '${drive.allowedDepartments.join(", ")}${drive.targetBatch != null ? " • ${drive.targetBatch}" : (drive.targetYear != null ? " • ${drive.targetYear}" : "")}',
                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                  isDark: isDark,
                ),

              if (drive.location != null)
                _buildTag(
                  icon: Icons.location_on_outlined,
                  text: drive.location!,
                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                  isDark: isDark,
                ),
              if (drive.minCgpa > 0)
                _buildTag(
                  icon: Icons.grade_outlined,
                  text: 'Min ${drive.minCgpa} CGPA',
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  isDark: isDark,
                ),
              if (drive.employmentType.isNotEmpty)
                _buildTag(
                  icon: Icons.badge_outlined,
                  text: drive.employmentType.replaceAll('_', ' '),
                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Info & Action
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: daysLeft <= 2 ? AppColors.error : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Deadline: $deadlineDateStr (${daysLeft > 0 ? "$daysLeft days left" : (daysLeft == 0 ? "today" : "closed")})',
                        style: AppTypography.micro.copyWith(
                          color: daysLeft <= 2
                              ? AppColors.error
                              : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                          fontWeight: daysLeft <= 2 ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isOfficer) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${drive.applicationCount} applied',
                    style: AppTypography.micro.copyWith(
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: AppTypography.captionMedium.copyWith(
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(String name, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.primaryBlue.withValues(alpha: 0.3), AppColors.secondaryCyan.withValues(alpha: 0.3)]
              : [AppColors.primaryBlue.withValues(alpha: 0.15), AppColors.secondaryCyan.withValues(alpha: 0.15)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: AppTypography.pageTitle.copyWith(
            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }


  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
