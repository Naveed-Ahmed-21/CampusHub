import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/campus_glass_card.dart';

class AdminAccessCard extends StatelessWidget {
  final bool isDeptAdmin;

  const AdminAccessCard({
    super.key,
    required this.isDeptAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final permissionsByCategory = <String, List<Map<String, String>>>{
      'PEOPLE': [
        {
          'title': 'User Management',
          'description': isDeptAdmin
              ? 'Department faculty and students directory'
              : 'Full directory of students, faculty, and administrative staff',
        },
      ],
      'ACADEMIC': [
        {
          'title': 'Academic Management',
          'description': isDeptAdmin
              ? 'Department syllabus and course assignments'
              : 'Institutional curriculum regulations, programs, and terms',
        },
        {
          'title': 'Departments',
          'description': isDeptAdmin
              ? 'Assigned department oversight'
              : 'All institutional departments configuration',
        },
        {
          'title': 'Subjects & Syllabus',
          'description': 'Course codes, semester mappings, and learning modules',
        },
        {
          'title': 'Timetable & Room Coordination',
          'description': 'Classroom allocations, period timings, and lecture schedules',
        },
      ],
      'CAMPUS': [
        {
          'title': 'Campus Feed & Broadcasts',
          'description': 'Official institutional notifications and public campus announcements',
        },
        {
          'title': 'Clubs & Communities',
          'description': 'Proposal review, leadership authorizations, and charter approvals',
        },
        {
          'title': 'Events & Fests',
          'description': 'College event permits, venue approvals, and schedule publication',
        },
        {
          'title': 'Content Moderation',
          'description': 'Policy enforcement, report auditing, and objectionable post removal',
        },
      ],
      'CAREER': [
        {
          'title': 'Placement Operations',
          'description': 'Recruiter onboarding, job drives, and eligibility verification',
        },
        {
          'title': 'Career Hub',
          'description': 'Industry skills frameworks, roadmaps, and interview preparation modules',
        },
      ],
      'INSIGHTS': [
        {
          'title': 'Reports & Analytics',
          'description': 'Enrolment metrics, attendance distribution, and institutional KPIs',
        },
      ],
      'SYSTEM': [
        {
          'title': 'Audit Logs & CSV Export',
          'description': 'Real-time RFC-4180 audit trail of governance actions',
        },
        {
          'title': 'Institutional Settings',
          'description': isDeptAdmin
              ? 'Restricted to College Administrator'
              : 'Primary campus configuration and academic calendar parameters',
        },
      ],
    };

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      borderRadius: AppRadius.br20,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_outlined, color: AppColors.electricBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access & Permissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Categorized governance capabilities granted under institutional RBAC.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 24),
          ...permissionsByCategory.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  item['description']!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AUTHORIZED',
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
