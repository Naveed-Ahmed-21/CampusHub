import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_status_badge.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_button.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';

class ShortlistResultsView extends ConsumerStatefulWidget {
  final String? driveId;

  const ShortlistResultsView({super.key, this.driveId});

  @override
  ConsumerState<ShortlistResultsView> createState() => _ShortlistResultsViewState();
}

class _ShortlistResultsViewState extends ConsumerState<ShortlistResultsView> {
  final Set<String> _selectedIds = {};
  bool _isProcessing = false;
  String? _currentDriveId;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _currentDriveId = widget.driveId;
  }

  Future<void> _performBulkAction(String status, [String? offerCtc]) async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(placementRepositoryProvider);
      await repo.bulkUpdateApplicationStatus(_selectedIds.toList(), status, offerCtc: offerCtc);
      ref.invalidate(placementApplicationsProvider(_currentDriveId));
      ref.invalidate(officerDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} candidates updated to $status!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _selectedIds.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drivesAsync = ref.watch(placementDrivesProvider);
    final appsAsync = ref.watch(placementApplicationsProvider(_currentDriveId));

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
                            'Shortlist & Results',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Drive shortlisting & selection management',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Blueprint Image 11: Drive Selector Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: drivesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (drives) {
                    if (drives.isEmpty) return const SizedBox.shrink();
                    // Set default drive if none selected
                    _currentDriveId ??= drives.first.id;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentDriveId,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                          items: drives.map((d) {
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Text(
                                '${d.companyName} — ${d.roleTitle}',
                                style: AppTypography.captionMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              setState(() {
                                _currentDriveId = newId;
                                _selectedIds.clear();
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Filter Tabs (Registered, Shortlisted, Selected, Rejected)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Candidates', isDark),
                    _buildFilterChip('APPLIED', 'Registered', isDark),
                    _buildFilterChip('SHORTLISTED', 'Shortlisted', isDark),
                    _buildFilterChip('OFFERED', 'Selected', isDark),
                    _buildFilterChip('REJECTED', 'Rejected', isDark),
                  ],
                ),
              ),

              // Applications List
              Expanded(
                child: appsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load candidates',
                    onRetry: () => ref.refresh(placementApplicationsProvider(_currentDriveId)),
                  ),
                  data: (applications) {
                    final filtered = applications.where((a) {
                      if (_statusFilter == 'ALL') return true;
                      return a.status == _statusFilter;
                    }).toList();

                    if (filtered.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Candidates Found',
                        description: _statusFilter == 'ALL'
                            ? 'No student applications available for this drive.'
                            : 'No candidates in the "$_statusFilter" stage.',
                        icon: Icons.checklist_outlined,
                      );
                    }

                    final allSelected = filtered.isNotEmpty && _selectedIds.length == filtered.length;

                    return Column(
                      children: [
                        // Select All Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.addAll(filtered.map((a) => a.id));
                                    } else {
                                      _selectedIds.clear();
                                    }
                                  });
                                },
                              ),
                              Text(
                                allSelected ? 'Deselect All' : 'Select All Candidates',
                                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '${_selectedIds.length} of ${filtered.length} selected',
                                style: AppTypography.micro.copyWith(
                                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List of Candidates
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final isChecked = _selectedIds.contains(app.id);

                              return CampusGlassCard(
                                intensity: GlassIntensity.medium,
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedIds.remove(app.id);
                                    } else {
                                      _selectedIds.add(app.id);
                                    }
                                  });
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isChecked,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedIds.add(app.id);
                                          } else {
                                            _selectedIds.remove(app.id);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    CampusAvatar(
                                      imageUrl: app.studentAvatar,
                                      name: app.studentName ?? app.studentEmail ?? 'Student',
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app.studentName ?? app.studentEmail ?? 'Student Candidate',
                                            style: AppTypography.captionMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${app.studentRoll ?? 'Roll N/A'} • ${app.departmentCode ?? 'Branch N/A'} • CGPA: ${app.studentCgpa}',
                                            style: AppTypography.micro.copyWith(
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CampusStatusBadge(
                                      label: app.status.replaceAll('_', ' '),
                                      type: app.status == 'OFFERED'
                                          ? StatusBadgeType.success
                                          : (app.status == 'SHORTLISTED' ? StatusBadgeType.info : StatusBadgeType.neutral),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Bulk Action Bar
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(
                      top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CampusButton(
                          label: 'Shortlist (${_selectedIds.length})',
                          icon: const Icon(Icons.check, size: 16),
                          type: CampusButtonType.secondary,
                          isLoading: _isProcessing,
                          onPressed: () => _performBulkAction('SHORTLISTED'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CampusButton(
                          label: 'Offer Job',
                          icon: const Icon(Icons.star_border, size: 16),
                          type: CampusButtonType.primary,
                          isLoading: _isProcessing,
                          onPressed: () => _performBulkAction('OFFERED'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        tooltip: 'Reject Selected',
                        onPressed: () => _performBulkAction('REJECTED'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.primaryText),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        selectedColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
        backgroundColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
        side: BorderSide(
          color: isSelected ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) {
            setState(() {
              _statusFilter = value;
              _selectedIds.clear();
            });
          }
        },
      ),
    );
  }
}

