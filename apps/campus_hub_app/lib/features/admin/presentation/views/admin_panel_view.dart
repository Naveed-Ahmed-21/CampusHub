import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

class AdminPanelView extends ConsumerStatefulWidget {
  const AdminPanelView({super.key});

  @override
  ConsumerState<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends ConsumerState<AdminPanelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusHub Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
            Tab(icon: Icon(Icons.business_rounded), text: 'Departments'),
            Tab(icon: Icon(Icons.groups_rounded), text: 'Clubs & Events'),
            Tab(icon: Icon(Icons.work_rounded), text: 'Placement'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Analytics'),
            Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Role Management'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(theme),
          _buildUsersTab(theme),
          _buildDepartmentsTab(theme),
          _buildClubsAndEventsTab(theme),
          _buildPlacementTab(theme),
          _buildAnalyticsTab(theme),
          _buildRoleManagementTab(theme),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildKpiCard('Total Users', '${metrics['totalUsers'] ?? 0}', Icons.people_outline, Colors.indigo),
                _buildKpiCard('Departments', '${metrics['totalDepartments'] ?? 0}', Icons.domain_outlined, Colors.teal),
                _buildKpiCard('Active Clubs', '${metrics['approvedClubs'] ?? 0}', Icons.groups_outlined, Colors.amber.shade800),
                _buildKpiCard('Pending Clubs', '${metrics['pendingClubs'] ?? 0}', Icons.pending_actions_outlined, Colors.orange),
                _buildKpiCard('Campus Events', '${metrics['totalEvents'] ?? 0}', Icons.event_outlined, Colors.purple),
                _buildKpiCard('Placement Drives', '${metrics['totalDrives'] ?? 0}', Icons.work_outline, Colors.blue),
                _buildKpiCard('Students Placed', '${metrics['placedCount'] ?? 0}', Icons.school_outlined, Colors.green),
                _buildKpiCard('System Status', 'HEALTHY', Icons.verified_outlined, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Admin Audit Activities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildAuditLogsList(),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load dashboard metrics'),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    final usersAsync = ref.watch(adminUsersProvider(role: _selectedRole, search: _searchController.text.isEmpty ? null : _searchController.text));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search user by name, email, or roll number...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedRole,
                hint: const Text('All Roles'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Roles')),
                  DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                  DropdownMenuItem(value: 'FACULTY', child: Text('Faculty')),
                  DropdownMenuItem(value: 'DEPT_ADMIN', child: Text('Dept Admin')),
                  DropdownMenuItem(value: 'COLLEGE_ADMIN', child: Text('College Admin')),
                  DropdownMenuItem(value: 'PLACEMENT_OFFICER', child: Text('Placement Officer')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              data: (users) => ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = users[index] as Map<String, dynamic>;
                  final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}';
                  final role = u['role'] ?? 'STUDENT';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      child: Text(name.isNotEmpty ? name[0] : 'U', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name.trim().isNotEmpty ? name : 'User'),
                    subtitle: Text('${u['email']} • ${u['roll_number'] ?? 'N/A'}'),
                    trailing: PopupMenuButton<String>(
                      child: Chip(
                        label: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: _getRoleColor(role)),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'STUDENT', child: Text('Set Role: STUDENT')),
                        const PopupMenuItem(value: 'FACULTY', child: Text('Set Role: FACULTY')),
                        const PopupMenuItem(value: 'DEPT_ADMIN', child: Text('Set Role: DEPT_ADMIN')),
                        const PopupMenuItem(value: 'COLLEGE_ADMIN', child: Text('Set Role: COLLEGE_ADMIN')),
                        const PopupMenuItem(value: 'PLACEMENT_OFFICER', child: Text('Set Role: PLACEMENT_OFFICER')),
                      ],
                      onSelected: (newRole) async {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated $name's role to $newRole")));
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorCard('Failed to fetch user directory'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsTab(ThemeData theme) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return deptsAsync.when(
      data: (depts) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('College Departments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddDepartmentDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Department'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: depts.length,
                itemBuilder: (context, index) {
                  final d = depts[index] as Map<String, dynamic>;
                  final userCount = (d['_count'] as Map?)?['users'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(d['code'] ?? 'D')),
                      title: Text(d['name'] ?? 'Department'),
                      subtitle: Text('Code: ${d['code']} • $userCount Enrolled Students & Faculty'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load departments'),
    );
  }

  Widget _buildClubsAndEventsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pending Club Verification Requests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.groups, color: Colors.white)),
            title: const Text('CyberSecurity & Ethical Hacking Guild'),
            subtitle: const Text('Category: Technical • Lead: Alex Vance'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () {}),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () {}),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('College & Department Event Moderation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_available, color: Colors.indigo, size: 36),
            title: const Text('Annual Tech Summit 2026'),
            subtitle: const Text('Scope: COLLEGE • Date: Nov 15 • Registrations: 142'),
            trailing: Chip(label: const Text('APPROVED'), backgroundColor: Colors.green.shade100),
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Placement Control Hub', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [Text('Placement Rate', style: TextStyle(color: Colors.grey)), Text('72.5%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))]),
                  Column(children: [Text('Avg Package', style: TextStyle(color: Colors.grey)), Text('14.5 LPA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]),
                  Column(children: [Text('Highest Package', style: TextStyle(color: Colors.grey)), Text('42.0 LPA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return analyticsAsync.when(
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Platform Analytics & Engagement', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Daily Users: ${data['engagementStats']?['activeDailyUsers'] ?? 890}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Event Attendance Rate: ${data['engagementStats']?['eventAttendanceRate'] ?? 84.2}%'),
                  const SizedBox(height: 8),
                  Text('Club Participation Rate: ${data['engagementStats']?['clubParticipationRate'] ?? 68.0}%'),
                ],
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load platform analytics'),
    );
  }

  Widget _buildRoleManagementTab(ThemeData theme) {
    const roles = [
      {'role': 'SUPER_ADMIN', 'desc': 'Full system control across all colleges and server infrastructure.'},
      {'role': 'COLLEGE_ADMIN', 'desc': 'Manage college departments, user verification, and campus-wide events.'},
      {'role': 'DEPT_ADMIN', 'desc': 'Department head / admin oversight for students and department posts.'},
      {'role': 'FACULTY', 'desc': 'Faculty member capabilities for event coordination and project mentoring.'},
      {'role': 'PLACEMENT_OFFICER', 'desc': 'Manage campus placement drives, student applications, and offer releases.'},
      {'role': 'CLUB_COORDINATOR', 'desc': 'Lead club activities, approve club events, and moderate club chats.'},
      {'role': 'STUDENT', 'desc': 'Standard student profile for feed participation, events, chat, and placements.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final r = roles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.shield_outlined, color: _getRoleColor(r['role']!)),
            title: Text(r['role']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(r['desc']!),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsList() {
    final reportsAsync = ref.watch(adminAuditReportsProvider);

    return reportsAsync.when(
      data: (logs) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final l = logs[index] as Map<String, dynamic>;
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text('${l['actorName']}: ${l['details']}'),
            subtitle: Text('${l['category']} • ${l['timestamp']}'),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
      case 'COLLEGE_ADMIN':
        return Colors.red;
      case 'DEPT_ADMIN':
        return Colors.purple;
      case 'PLACEMENT_OFFICER':
        return Colors.blue;
      case 'FACULTY':
        return Colors.teal;
      case 'CLUB_COORDINATOR':
        return Colors.amber.shade800;
      default:
        return Colors.indigo;
    }
  }

  void _showAddDepartmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Department Name')),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Department Code (e.g. CSE)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department added successfully')));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
