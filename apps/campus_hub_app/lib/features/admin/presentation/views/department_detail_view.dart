import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_glass_panel.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../providers/admin_provider.dart';

class DepartmentDetailView extends ConsumerWidget {
  final String departmentId;
  final String departmentName;
  final String? departmentCode;

  const DepartmentDetailView({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(adminDepartmentOverviewProvider(departmentId));

    return Scaffold(
      appBar: CampusAppBar(
        leading: const CampusBackButton(),
        title: departmentCode != null ? '$departmentName ($departmentCode)' : departmentName,
      ),
      body: AtmosphericBackground(
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text('Failed to load department overview: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(adminDepartmentOverviewProvider(departmentId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (overview) {
            final deptName = overview['name']?.toString() ?? departmentName;
            final code = overview['code']?.toString() ?? departmentCode ?? '';
            final totalStudents = overview['totalStudents'] ?? overview['total_students'] ?? 0;
            final totalFaculty = overview['totalFaculty'] ?? overview['total_faculty'] ?? 0;
            final byYear = overview['studentsByYear'] as Map<String, dynamic>? ?? {};

            final firstYear = byYear['firstYear'] ?? 0;
            final secondYear = byYear['secondYear'] ?? 0;
            final thirdYear = byYear['thirdYear'] ?? 0;
            final fourthYear = byYear['fourthYear'] ?? 0;
            final graduated = byYear['graduated'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Department Header Card
                  CampusGlassPanel(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                code.isNotEmpty ? code : 'D',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deptName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  if (code.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Code: $code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        // Real database statistics
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                context,
                                label: 'Total Students',
                                value: '$totalStudents',
                                icon: Icons.school_rounded,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                context,
                                label: 'Total Faculty',
                                value: '$totalFaculty',
                                icon: Icons.badge_rounded,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Students by Year Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STUDENTS BY YEAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total: $totalStudents',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildYearCard(
                    context,
                    yearLabel: '1st Year',
                    yearNumber: 1,
                    count: firstYear,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildYearCard(
                    context,
                    yearLabel: '2nd Year',
                    yearNumber: 2,
                    count: secondYear,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 8),
                  _buildYearCard(
                    context,
                    yearLabel: '3rd Year',
                    yearNumber: 3,
                    count: thirdYear,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 8),
                  _buildYearCard(
                    context,
                    yearLabel: '4th Year',
                    yearNumber: 4,
                    count: fourthYear,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 8),
                  _buildYearCard(
                    context,
                    yearLabel: 'Graduated',
                    yearNumber: 5,
                    count: graduated,
                    color: Colors.blueGrey,
                  ),

                  const SizedBox(height: 28),

                  // Faculty Members Section
                  Text(
                    'FACULTY DIRECTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DepartmentFacultyListView(
                            departmentId: departmentId,
                            departmentName: deptName,
                          ),
                        ),
                      );
                    },
                    child: CampusGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Colors.teal, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Department Faculty Members',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View profiles, assigned subjects, and contact details',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$totalFaculty',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context, {
    required String yearLabel,
    required int yearNumber,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DepartmentYearStudentsListView(
              departmentId: departmentId,
              departmentName: departmentName,
              yearLabel: yearLabel,
              yearNumber: yearNumber,
            ),
          ),
        );
      },
      child: CampusGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  yearNumber == 5 ? 'G' : '$yearNumber',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                yearLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$count Students',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Year-Wise Student List Screen
class DepartmentYearStudentsListView extends ConsumerStatefulWidget {
  final String departmentId;
  final String departmentName;
  final String yearLabel;
  final int yearNumber;

  const DepartmentYearStudentsListView({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.yearLabel,
    required this.yearNumber,
  });

  @override
  ConsumerState<DepartmentYearStudentsListView> createState() => _DepartmentYearStudentsListViewState();
}

class _DepartmentYearStudentsListViewState extends ConsumerState<DepartmentYearStudentsListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filter = DepartmentStudentsFilter(
      departmentId: widget.departmentId,
      year: widget.yearLabel,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: 1,
      limit: 100,
    );

    final studentsAsync = ref.watch(adminDepartmentStudentsProvider(filter));

    return Scaffold(
      appBar: CampusAppBar(
        leading: const CampusBackButton(),
        title: widget.yearLabel,
        subtitle: widget.departmentName,
      ),
      body: AtmosphericBackground(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, roll no, reg no, or user ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

            // Students Content
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text('Failed to load students: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(adminDepartmentStudentsProvider(filter)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (res) {
                  final students = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final total = res['meta']?['total'] ?? students.length;

                  if (students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No students found matching "$_searchQuery"'
                                : 'No students found in ${widget.yearLabel}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          'Total Students: $total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = students[index];
                            final fullName = s['fullName'] ?? '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
                            final userId = s['id']?.toString() ?? '';
                            final rollNo = s['rollNumber'] ?? 'N/A';
                            final regNo = s['registrationNumber'] ?? s['rollNumber'] ?? 'N/A';
                            final currentYear = s['currentYear'] ?? widget.yearLabel;
                            final status = s['status']?.toString() ?? 'ACTIVE';
                            final avatarUrl = s['avatarUrl']?.toString();

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                // Navigate to existing user profile
                                if (userId.isNotEmpty) {
                                  context.push('/profile/$userId');
                                }
                              },
                              child: CampusGlassPanel(
                                padding: const EdgeInsets.all(14),
                                borderRadius: BorderRadius.circular(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CampusAvatar(
                                      imageUrl: avatarUrl,
                                      name: fullName.isNotEmpty ? fullName : 'S',
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fullName,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              _buildStatusBadge(status),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // User ID
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'User ID: $userId',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 14),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Copy User ID',
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: userId));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('User ID copied to clipboard'),
                                                      duration: Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'Reg No: $regNo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                'Roll No: $rollNo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                              Text(
                                                'Year: $currentYear',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'INVITED' || status == 'PASSWORD_SETUP_REQUIRED') {
      color = Colors.orange;
    } else if (status == 'DEACTIVATED' || status == 'SUSPENDED') {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

/// Faculty List Screen
class DepartmentFacultyListView extends ConsumerStatefulWidget {
  final String departmentId;
  final String departmentName;

  const DepartmentFacultyListView({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  ConsumerState<DepartmentFacultyListView> createState() => _DepartmentFacultyListViewState();
}

class _DepartmentFacultyListViewState extends ConsumerState<DepartmentFacultyListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filter = DepartmentFacultyFilter(
      departmentId: widget.departmentId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: 1,
      limit: 100,
    );

    final facultyAsync = ref.watch(adminDepartmentFacultyProvider(filter));

    return Scaffold(
      appBar: CampusAppBar(
        leading: const CampusBackButton(),
        title: 'Faculty Members',
        subtitle: widget.departmentName,
      ),
      body: AtmosphericBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by faculty name, email, or user ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
            Expanded(
              child: facultyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text('Failed to load faculty: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(adminDepartmentFacultyProvider(filter)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (res) {
                  final facultyList = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final total = res['meta']?['total'] ?? facultyList.length;

                  if (facultyList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No faculty found matching "$_searchQuery"'
                                : 'No faculty members found in this department',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          'Total Faculty: $total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: facultyList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final f = facultyList[index];
                            final fullName = f['fullName'] ?? '${f['firstName'] ?? ''} ${f['lastName'] ?? ''}'.trim();
                            final userId = f['id']?.toString() ?? '';
                            final email = f['email']?.toString() ?? '';
                            final designation = f['designation']?.toString() ?? 'Faculty';
                            final officeRoom = f['officeRoom']?.toString() ?? '';
                            final status = f['status']?.toString() ?? 'ACTIVE';
                            final avatarUrl = f['avatarUrl']?.toString();
                            final assignedSubjects = (f['assignedSubjects'] as List?)?.cast<String>() ?? [];

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (userId.isNotEmpty) {
                                  context.push('/profile/$userId');
                                }
                              },
                              child: CampusGlassPanel(
                                padding: const EdgeInsets.all(14),
                                borderRadius: BorderRadius.circular(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CampusAvatar(
                                      imageUrl: avatarUrl,
                                      name: fullName,
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fullName,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              _buildStatusBadge(status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            designation,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Real Database User ID
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'User ID: $userId',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 14),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Copy User ID',
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: userId));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('User ID copied to clipboard'),
                                                      duration: Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Email: $email',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          if (officeRoom.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Room: $officeRoom',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                          if (assignedSubjects.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: assignedSubjects.map((sub) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    sub,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'INVITED' || status == 'PASSWORD_SETUP_REQUIRED') {
      color = Colors.orange;
    } else if (status == 'DEACTIVATED' || status == 'SUSPENDED') {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
