import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
import '../../../../core/widgets/campus_dialog.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

class ApplicationsView extends ConsumerStatefulWidget {
  final String? driveId;

  const ApplicationsView({super.key, this.driveId});

  @override
  ConsumerState<ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends ConsumerState<ApplicationsView> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _statusFilters = [
    'ALL',
    'APPLIED',
    'SHORTLISTED',
    'INTERVIEW_SCHEDULED',
    'OFFERED',
    'REJECTED',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showInterviewScheduleDialog(PlacementApplicationModel app) {
    final roundCtrl = TextEditingController(text: 'Technical Round 1');
    final venueCtrl = TextEditingController(text: 'Google Meet / Lab 3');
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CampusDialog(
          title: 'Schedule Interview',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Candidate: ${app.studentName ?? app.studentEmail ?? 'Student'}',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              CampusTextField(
                controller: roundCtrl,
                label: 'Round Name *',
                prefixIcon: Icons.badge_outlined,
                hint: 'e.g. Technical Round 1, HR Round',
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Interview Date & Time'),
                subtitle: Text(scheduledDate.toLocal().toString().substring(0, 16)),
                trailing: TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: ctx,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (pickedDate != null && ctx.mounted) {
                      final pickedTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(scheduledDate),
                      );
                      if (pickedTime != null) {
                        setDialogState(() {
                          scheduledDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 8),
              CampusTextField(
                controller: venueCtrl,
                label: 'Venue or Virtual Link',
                prefixIcon: Icons.location_on_outlined,
              ),
            ],
          ),
          actions: [
            CampusButton(
              label: 'Cancel',
              type: CampusButtonType.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            CampusButton(
              label: 'Schedule',
              type: CampusButtonType.primary,
              onPressed: () async {
                if (roundCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  final repo = ref.read(placementRepositoryProvider);
                  await repo.scheduleInterview(
                    applicationId: app.id,
                    roundName: roundCtrl.text.trim(),
                    scheduledAt: scheduledDate.toUtc().toIso8601String(),
                    locationOrLink: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : null,
                  );
                  ref.invalidate(placementApplicationsProvider(widget.driveId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Interview scheduled! Candidate notified.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(PlacementApplicationModel app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Application: ${app.studentName ?? 'Candidate'}',
                style: AppTypography.captionMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Roll: ${app.studentRoll ?? 'N/A'} • Branch: ${app.departmentCode ?? 'N/A'} • CGPA: ${app.studentCgpa}',
                style: AppTypography.micro.copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              if (app.resumeUrl != null && app.resumeUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryBlue),
                  title: const Text('View Candidate Resume'),
                  subtitle: Text(app.resumeUrl!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.launch, size: 16),
                  onTap: () => launchUrlString(app.resumeUrl!, mode: LaunchMode.externalApplication),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Update Candidate Status', style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CampusButton(
                    label: 'Shortlist',
                    icon: const Icon(Icons.check, size: 16),
                    type: CampusButtonType.secondary,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _updateStatus(app.id, 'SHORTLISTED');
                    },
                  ),
                  CampusButton(
                    label: 'Schedule Interview',
                    icon: const Icon(Icons.calendar_today, size: 16),
                    type: CampusButtonType.primary,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showInterviewScheduleDialog(app);
                    },
                  ),
                  CampusButton(
                    label: 'Extend Offer',
                    icon: const Icon(Icons.star_border, size: 16),
                    type: CampusButtonType.secondary,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _updateStatus(app.id, 'OFFERED');
                    },
                  ),
                  CampusButton(
                    label: 'Reject',
                    icon: const Icon(Icons.close, size: 16),
                    type: CampusButtonType.ghost,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _updateStatus(app.id, 'REJECTED');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String applicationId, String status) async {
    try {
      final repo = ref.read(placementRepositoryProvider);
      await repo.updateApplicationStatus(applicationId, status);
      ref.invalidate(placementApplicationsProvider(widget.driveId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application marked as $status'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appsAsync = ref.watch(placementApplicationsProvider(widget.driveId));

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
                            'Student Applications',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Review candidates, shortlist, and schedule interviews',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.checklist_rtl_outlined),
                      tooltip: 'Bulk Actions',
                      onPressed: () {
                        context.push('/placement/shortlist${widget.driveId != null ? '?drive_id=${widget.driveId}' : ''}');
                      },
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
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                      hintText: 'Search by student name or roll number...',
                      hintStyle: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Status Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _statusFilters.map((st) {
                    final isSelected = _selectedStatus == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          st == 'ALL' ? 'All' : st.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.primaryText),
                          ),
                        ),
                        selectedColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatus = st);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Applications List
              Expanded(
                child: appsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load candidate applications',
                    onRetry: () => ref.refresh(placementApplicationsProvider(widget.driveId)),
                  ),
                  data: (applications) {
                    final filtered = applications.where((a) {
                      if (_selectedStatus != 'ALL' && a.status != _selectedStatus) return false;
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      final name = (a.studentName ?? '').toLowerCase();
                      final roll = (a.studentRoll ?? '').toLowerCase();
                      final email = (a.studentEmail ?? '').toLowerCase();
                      return name.contains(q) || roll.contains(q) || email.contains(q);
                    }).toList();

                    if (filtered.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Applications Found',
                        description: _searchQuery.isEmpty
                            ? 'No student applications in this status category.'
                            : 'No applicants match "$_searchQuery".',
                        icon: Icons.people_outline,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(placementApplicationsProvider(widget.driveId)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final app = filtered[index];
                          return _buildCandidateCard(context, app, isDark);
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
    );
  }

  Widget _buildCandidateCard(BuildContext context, PlacementApplicationModel app, bool isDark) {
    StatusBadgeType badgeType;
    if (app.status == 'OFFERED') {
      badgeType = StatusBadgeType.success;
    } else if (app.status == 'SHORTLISTED' || app.status == 'INTERVIEW_SCHEDULED') {
      badgeType = StatusBadgeType.info;
    } else if (app.status == 'REJECTED') {
      badgeType = StatusBadgeType.danger;
    } else {
      badgeType = StatusBadgeType.neutral;
    }

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      onTap: () => context.push('/placement/applications/${app.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CampusAvatar(
            imageUrl: app.studentAvatar,
            name: app.studentName ?? app.studentEmail ?? 'Student',
            radius: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.studentName ?? app.studentEmail ?? 'Student Candidate',
                  style: AppTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppColors.darkText : AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${app.studentRoll ?? 'Roll N/A'} • ${app.departmentCode ?? 'Branch N/A'}',
                  style: AppTypography.micro.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CGPA: ${app.studentCgpa > 0 ? app.studentCgpa : 'N/A'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CampusStatusBadge(
                      label: app.status.replaceAll('_', ' '),
                      type: badgeType,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showStatusDialog(app),
          ),
        ],
      ),
    );
  }
}
