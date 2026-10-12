import '../../../../core/widgets/campus_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_status_chip.dart';
import '../../../clubs/domain/club_models.dart';
import '../../../clubs/presentation/providers/club_provider.dart';
import '../../../clubs/data/clubs_repository.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'admin_dashboard_view.dart';
import 'department_detail_view.dart';
import '../widgets/admin_drawer_widget.dart';
import '../widgets/admin_top_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_panel.dart';
import '../../../../core/widgets/campus_card.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/utils/app_date_formatter.dart';

enum AcademicSection { yearsTerms, programs, batches, courses, classes, rooms, timetable }
enum ModerationSection { clubs, events, posts }
enum ClubModerationSubSection { pending, active }
enum SettingsSection { profile, adminProfile, auditLogs, roles }

class AdminPanelView extends ConsumerStatefulWidget {
  const AdminPanelView({super.key});

  @override
  ConsumerState<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends ConsumerState<AdminPanelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _auditActionController = TextEditingController();
  String? _selectedRole;
  String? _selectedAuditCategory;
  String? _selectedChangeRequestStatus = 'PENDING';
  String? _selectedChangeRequestCategory;
  AcademicSection _academicSection = AcademicSection.yearsTerms;
  ModerationSection _moderationSection = ModerationSection.clubs;
  ClubModerationSubSection _clubSubSection = ClubModerationSubSection.pending;
  SettingsSection _settingsSection = SettingsSection.profile;
  String _selectedPlacementStatus = 'ALL';
  final TextEditingController _placementSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _auditActionController.dispose();
    _placementSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final pendingRequestsCount = ref.watch(adminPendingChangeRequestsCountProvider).value ?? 0;

    final tabViews = [
      _buildDashboardTab(theme),
      _buildUsersTab(theme),
      _buildDepartmentsTab(theme),
      _buildAcademicStructureTab(theme),
      _buildClubsAndEventsTab(theme),
      _buildPlacementTab(theme),
      _buildAnalyticsTab(theme),
      _buildSettingsAndGovernanceTab(theme),
      _buildChangeRequestsTab(theme),
    ];

    if (isWide) {
      return Scaffold(
        drawer: AdminDrawerWidget(onSelectTab: (index) => _tabController.animateTo(index)),
        appBar: const AdminTopBar(
          title: 'CampusHub Admin Panel',
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tabController.index,
              onDestinationSelected: (index) {
                _tabController.animateTo(index);
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.admin_panel_settings, size: 32, color: theme.primaryColor),
              ),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                const NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: Text('Users')),
                const NavigationRailDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business_rounded), label: Text('Departments')),
                const NavigationRailDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance_rounded), label: Text('Academics')),
                const NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: Text('Clubs & Events')),
                const NavigationRailDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work_rounded), label: Text('Placement')),
                const NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: Text('Analytics')),
                const NavigationRailDestination(icon: Icon(Icons.settings_suggest_outlined), selectedIcon: Icon(Icons.settings_suggest_rounded), label: Text('Settings & Governance')),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: pendingRequestsCount > 0,
                    label: Text('$pendingRequestsCount'),
                    child: const Icon(Icons.pending_actions_outlined),
                  ),
                  selectedIcon: const Icon(Icons.pending_actions_rounded),
                  label: const Text('Requests'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: AtmosphericBackground(
                child: TabBarView(
                  controller: _tabController,
                  children: tabViews,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: AdminDrawerWidget(onSelectTab: (index) => _tabController.animateTo(index)),
      appBar: const AdminTopBar(
        title: 'CampusHub Admin Panel',
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.4),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Dashboard'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Users'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Departments'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Academics'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Clubs & Events'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Placement'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Analytics'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_suggest_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Settings & Governance'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: pendingRequestsCount > 0,
                          label: Text('$pendingRequestsCount'),
                          child: const Icon(Icons.pending_actions_rounded, size: 16),
                        ),
                        const SizedBox(width: 6),
                        const Text('Requests'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AtmosphericBackground(
              child: TabBarView(
                controller: _tabController,
                children: tabViews,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DASHBOARD TAB
  // ==========================================
  Widget _buildDashboardTab(ThemeData theme) {
    return AdminDashboardView(
      onNavigateToSection: (section) {
        switch (section) {
          case 'users':
            _tabController.animateTo(1);
            break;
          case 'departments':
            _tabController.animateTo(2);
            break;
          case 'classes':
            _tabController.animateTo(3);
            setState(() => _academicSection = AcademicSection.classes);
            break;
          case 'timetable':
            _tabController.animateTo(3);
            setState(() => _academicSection = AcademicSection.timetable);
            break;
          case 'academics':
            _tabController.animateTo(3);
            break;
          case 'clubs':
            _tabController.animateTo(4);
            setState(() => _moderationSection = ModerationSection.clubs);
            break;
          case 'events':
            _tabController.animateTo(4);
            setState(() => _moderationSection = ModerationSection.events);
            break;
          case 'moderation':
            _tabController.animateTo(4);
            setState(() => _moderationSection = ModerationSection.posts);
            break;
          case 'placement':
            _tabController.animateTo(5);
            break;
          case 'analytics':
            _tabController.animateTo(6);
            break;
          case 'settings':
            _tabController.animateTo(7);
            break;
          case 'profile':
            _tabController.animateTo(7);
            setState(() => _settingsSection = SettingsSection.profile);
            break;
          case 'audit_logs':
            _tabController.animateTo(7);
            setState(() => _settingsSection = SettingsSection.auditLogs);
            break;
          case 'requests':
          case 'change_requests':
          case 'change-requests':
            _tabController.animateTo(8);
            break;
          case 'feed':
            context.push('/feed');
            break;
        }
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? AppColors.darkText : AppColors.primaryNavy;
    final labelColor = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return CampusCard(
      onTap: onTap,
      padding: AppSpacing.p12,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // USERS TAB
  // ==========================================
  Widget _buildUsersTab(ThemeData theme) {
    final filter = AdminUsersFilter(
      role: _selectedRole,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
    final usersAsync = ref.watch(adminUsersProvider(filter));
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentAuthUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = currentAuthUser?.id;
    final currentUserEmail = currentAuthUser?.email.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search name, email, roll no...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRecycleBinDialog(context),
                  icon: const Icon(Icons.auto_delete_outlined, color: Colors.orange, size: 20),
                  tooltip: 'Recycle Bin (Deleted Users)',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Role Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(_selectedRole),
                    isExpanded: true,
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Roles', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'DEPT_ADMIN', child: Text('Dept Admin', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'FACULTY', child: Text('Faculty', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'PLACEMENT', child: Text('Placement', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'STUDENT', child: Text('Student', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                ),
              ],
            ),
          ] else ...[
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
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRole,
                  hint: const Text('All Roles'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Roles')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    DropdownMenuItem(value: 'DEPT_ADMIN', child: Text('Dept Admin')),
                    DropdownMenuItem(value: 'FACULTY', child: Text('Faculty')),
                    DropdownMenuItem(value: 'PLACEMENT', child: Text('Placement')),
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRecycleBinDialog(context),
                  icon: const Icon(Icons.auto_delete_outlined, color: Colors.orange, size: 18),
                  label: const Text('Recycle Bin'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add User'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final visibleUsers = users.where((item) {
                  if (item is! Map<String, dynamic>) return false;
                  final uid = item['id']?.toString();
                  final uemail = item['email']?.toString().toLowerCase();
                  if (currentUserId != null && uid == currentUserId) return false;
                  if (currentUserEmail != null && uemail == currentUserEmail) return false;
                  return true;
                }).toList();

                if (visibleUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found matching current filters.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  itemCount: visibleUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final u = visibleUsers[index] as Map<String, dynamic>;
                    final userId = u['id']?.toString() ?? '';
                    final firstName = u['first_name'] ?? '';
                    final lastName = u['last_name'] ?? '';
                    final name = '$firstName $lastName'.trim();
                    final role = u['role'] ?? 'STUDENT';
                    final status = u['status']?.toString().toUpperCase() ?? 'ACTIVE';
                    final isActive = status == 'ACTIVE';
                    final deptName = u['department']?['name'] ?? u['department']?['code'] ?? 'No Dept';

                    return CampusGlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    final rawAvatar = u['avatar_url'] ?? u['avatarUrl'];
                                    final resolvedAvatar = rawAvatar != null && rawAvatar.toString().trim().isNotEmpty
                                        ? ApiEndpoints.resolveUrl(rawAvatar.toString().trim())
                                        : null;
                                    return CampusAvatar(
                                      imageUrl: resolvedAvatar,
                                      name: name,
                                      radius: 20,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name.isNotEmpty ? name : 'User',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                decoration: isActive ? null : TextDecoration.lineThrough,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        u['email'] ?? '',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  tooltip: 'Change Role',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(role).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getRoleColor(role).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getRoleColor(role),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_drop_down, size: 14, color: _getRoleColor(role)),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'STUDENT', child: Text('Set Role: STUDENT')),
                                    const PopupMenuItem(value: 'FACULTY', child: Text('Set Role: FACULTY')),
                                    const PopupMenuItem(value: 'DEPT_ADMIN', child: Text('Set Role: DEPT_ADMIN')),
                                    const PopupMenuItem(value: 'PLACEMENT', child: Text('Set Role: PLACEMENT')),
                                    const PopupMenuItem(value: 'ADMIN', child: Text('Set Role: ADMIN')),
                                  ],
                                  onSelected: (newRole) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await ref.read(adminRemoteDataSourceProvider).updateUserRole(userId, newRole);
                                      ref.invalidate(adminUsersProvider);
                                      ref.invalidate(adminAuditReportsProvider);
                                      messenger.showSnackBar(
                                        SnackBar(content: Text("Updated $name's role to $newRole")),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 18, thickness: 0.5),
                            Row(
                              children: [
                                Icon(Icons.business_outlined, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$deptName • Roll: ${u['roll_number'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: 'Edit User Profile',
                                  onPressed: () => _showEditUserDialog(context, u),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: 'Delete User Account',
                                  onPressed: () => _showDeleteUserDialog(context, u),
                                ),
                                const SizedBox(width: 4),
                                _UserStatusSwitch(
                                  userId: userId,
                                  initialActive: isActive,
                                  ref: ref,
                                ),
                              ],
                            ),
                          ],
                        ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorCard('Failed to fetch user directory'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEPARTMENTS TAB
  // ==========================================
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
              child: depts.isEmpty
                  ? const Center(child: Text('No departments configured yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: depts.length,
                      itemBuilder: (context, index) {
                        final d = depts[index] as Map<String, dynamic>;
                        final studentCount = d['totalStudents'] ?? d['total_students'] ?? 0;
                        final facultyCount = d['totalFaculty'] ?? d['total_faculty'] ?? 0;
                        final isActive = d['is_active'] ?? true;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => DepartmentDetailView(
                                  departmentId: d['id'].toString(),
                                  departmentName: d['name']?.toString() ?? 'Department',
                                  departmentCode: d['code']?.toString(),
                                ),
                              ),
                            );
                          },
                          child: CampusGlassPanel(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            d['code'] ?? 'D',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['name'] ?? 'Department',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            softWrap: true,
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Code: ${d['code'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? Colors.green.withValues(alpha: 0.12)
                                                      : Colors.red.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isActive
                                                        ? Colors.green.withValues(alpha: 0.3)
                                                        : Colors.red.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  isActive ? 'ACTIVE' : 'INACTIVE',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isActive ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                                if (d['description'] != null && (d['description'] as String).trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    d['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Real database metrics
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.school_outlined, size: 14, color: AppColors.primaryBlue),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Students: $studentCount',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 14, color: Colors.teal),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Faculty: $facultyCount',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: 6),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.analytics_outlined, size: 16),
                                      label: const Text('Department Overview', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => DepartmentDetailView(
                                              departmentId: d['id'].toString(),
                                              departmentName: d['name']?.toString() ?? 'Department',
                                              departmentCode: d['code']?.toString(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isActive ? Icons.block_outlined : Icons.check_circle_outline,
                                            color: isActive ? Colors.orange : Colors.green,
                                            size: 18,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          tooltip: isActive ? 'Deactivate Department' : 'Activate Department',
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            try {
                                              await ref.read(adminRemoteDataSourceProvider).updateDepartmentStatus(d['id'].toString(), !isActive);
                                              ref.invalidate(adminDepartmentsProvider);
                                              ref.invalidate(adminMetricsProvider);
                                              ref.invalidate(adminAuditReportsProvider);
                                              messenger.showSnackBar(
                                                SnackBar(content: Text("Department '${d['name']}' ${!isActive ? 'activated' : 'deactivated'} successfully")),
                                              );
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          tooltip: 'Edit Department',
                                          onPressed: () => _showEditDepartmentDialog(context, d),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          tooltip: 'Delete Department',
                                          onPressed: () => _showDeleteDepartmentDialog(context, d),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

  // ==========================================
  // ACADEMIC STRUCTURE TAB (PHASE 3)
  // ==========================================
  Widget _buildAcademicStructureTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dedicated Academic Structure Tab List (Full Width, Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<AcademicSection>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: AcademicSection.yearsTerms,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Years & Terms')),
                  icon: Icon(Icons.calendar_today_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.programs,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Programs')),
                  icon: Icon(Icons.school_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.batches,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Batches')),
                  icon: Icon(Icons.calendar_month_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.courses,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Subjects')),
                  icon: Icon(Icons.menu_book_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.classes,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Classes')),
                  icon: Icon(Icons.class_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.rooms,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Rooms')),
                  icon: Icon(Icons.meeting_room_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AcademicSection.timetable,
                  label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Timetable')),
                  icon: Icon(Icons.schedule_outlined, size: 16),
                ),
              ],
              selected: {_academicSection},
              onSelectionChanged: (set) => setState(() => _academicSection = set.first),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Separate Action Header Bar with Section Title and Add New Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getAcademicSectionTitle(_academicSection),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _buildAddAcademicButton(context, _academicSection),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _academicSection == AcademicSection.yearsTerms
                ? _buildAcademicYearsView(theme)
                : _academicSection == AcademicSection.programs
                    ? _buildProgramsView(theme)
                    : _academicSection == AcademicSection.batches
                        ? _buildBatchesView(theme)
                        : _academicSection == AcademicSection.courses
                            ? _buildSubjectsView(theme)
                            : _academicSection == AcademicSection.classes
                                ? _buildClassesView(theme)
                                : _academicSection == AcademicSection.rooms
                                    ? _buildRoomsView(theme)
                                    : _buildTimetableView(theme),
          ),
        ],
      ),
    );
  }

  String _getAcademicSectionTitle(AcademicSection section) {
    switch (section) {
      case AcademicSection.yearsTerms:
        return 'Academic Years & Terms';
      case AcademicSection.programs:
        return 'Academic Programs & Degrees';
      case AcademicSection.batches:
        return 'Student Batches';
      case AcademicSection.courses:
        return 'Courses & Subjects';
      case AcademicSection.classes:
        return 'Class Sections';
      case AcademicSection.rooms:
        return 'Lecture Halls & Labs';
      case AcademicSection.timetable:
        return 'Timetable Schedule';
    }
  }

  Widget _buildAddAcademicButton(BuildContext context, AcademicSection section) {
    switch (section) {
      case AcademicSection.yearsTerms:
        return ElevatedButton.icon(
          onPressed: () => _showAddAcademicYearDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Academic Year'),
        );
      case AcademicSection.programs:
        return ElevatedButton.icon(
          onPressed: () => _showAddProgramDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Program'),
        );
      case AcademicSection.batches:
        return ElevatedButton.icon(
          onPressed: () => _showAddBatchDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Batch'),
        );
      case AcademicSection.courses:
        return ElevatedButton.icon(
          onPressed: () => _showAddSubjectDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Subject'),
        );
      case AcademicSection.classes:
        return ElevatedButton.icon(
          onPressed: () => _showAddClassDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Class'),
        );
      case AcademicSection.rooms:
        return ElevatedButton.icon(
          onPressed: () => _showAddRoomDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Room'),
        );
      case AcademicSection.timetable:
        return ElevatedButton.icon(
          onPressed: () => _showAddScheduleDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Timetable Slot'),
        );
    }
  }

  Widget _buildAcademicYearsView(ThemeData theme) {
    final yearsAsync = ref.watch(adminAcademicYearsProvider);

    return yearsAsync.when(
      data: (years) {
        if (years.isEmpty) {
          return const Center(child: Text('No academic years created yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: years.length,
          itemBuilder: (context, index) {
            final y = years[index] as Map<String, dynamic>;
            final yearId = y['id']?.toString() ?? '';
            final isActive = y['is_active'] == true;
            final termsCount = (y['_count'] as Map?)?['terms'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(Icons.calendar_today, color: isActive ? Colors.green : Colors.grey),
                title: Row(
                  children: [
                    Text(y['year_name'] ?? 'Academic Year', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(isActive ? 'CURRENT' : 'INACTIVE', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                  ],
                ),
                subtitle: Text('Dates: ${y['start_date']?.toString().split('T').first ?? ''} to ${y['end_date']?.toString().split('T').first ?? ''} • $termsCount Terms'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(adminRemoteDataSourceProvider).setActiveAcademicYear(yearId);
                            ref.invalidate(adminAcademicYearsProvider);
                            ref.invalidate(adminAuditReportsProvider);
                            messenger.showSnackBar(SnackBar(content: Text("Activated academic year '${y['year_name']}'")));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                          }
                        },
                        child: const Text('Set Active'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Academic Year',
                      onPressed: () => _showEditAcademicYearDialog(context, y),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Term to Year',
                      onPressed: () => _showAddTermDialog(context, yearId, y['year_name'] ?? ''),
                    ),
                  ],
                ),
                children: [
                  _buildTermsSublist(yearId),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load academic years'),
    );
  }

  Widget _buildTermsSublist(String yearId) {
    final termsAsync = ref.watch(adminAcademicTermsProvider(yearId));

    return termsAsync.when(
      data: (terms) {
        if (terms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('No terms/semesters added for this academic year yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: terms.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final t = terms[i] as Map<String, dynamic>;
            return ListTile(
              dense: true,
              leading: CircleAvatar(radius: 12, child: Text('${t['semester_number'] ?? i + 1}', style: const TextStyle(fontSize: 10))),
              title: Text(t['name'] ?? 'Term'),
              subtitle: Text('Type: ${t['term_type']} • Status: ${t['status']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    tooltip: 'Edit Term',
                    onPressed: () => _showEditTermDialog(context, yearId, t),
                  ),
                  Chip(
                    label: Text(t['status'] ?? 'UPCOMING', style: const TextStyle(fontSize: 8)),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
      error: (_, __) => const Text('Failed to load terms', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildProgramsView(ThemeData theme) {
    final programsAsync = ref.watch(adminProgramsProvider(null));

    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No academic programs registered yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final p = programs[index] as Map<String, dynamic>;
            final dept = p['department'] as Map<String, dynamic>?;
            final deptName = dept?['name'] ?? dept?['code'] ?? 'Department';
            final studentCount = (p['_count'] as Map?)?['student_profiles'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(p['code']?[0] ?? 'P', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
                title: Text('${p['code']} - ${p['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$deptName • ${p['degree_type']} • ${p['total_semesters']} Semesters • $studentCount Enrolled'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Program',
                      onPressed: () => _showEditProgramDialog(context, p),
                    ),
                    Chip(
                      label: Text(p['is_active'] == true ? 'ACTIVE' : 'INACTIVE', style: const TextStyle(fontSize: 9)),
                      backgroundColor: p['is_active'] == true ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load academic programs'),
    );
  }

  Widget _buildBatchesView(ThemeData theme) {
    final batchesAsync = ref.watch(adminBatchesProvider(null));

    return batchesAsync.when(
      data: (batches) {
        if (batches.isEmpty) {
          return const Center(child: Text('No student batches configured yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final b = batches[index] as Map<String, dynamic>;
            final prog = b['program'] as Map<String, dynamic>?;
            final progName = prog?['name'] ?? prog?['code'] ?? 'All Programs';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.school, color: Colors.white, size: 20),
                ),
                title: Text(b['name'] ?? 'Batch', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Cohort: ${b['admission_year']} - ${b['graduation_year']} • Program: $progName'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Batch',
                      onPressed: () => _showEditBatchDialog(context, b),
                    ),
                    Chip(
                      label: Text(b['status'] ?? 'ACTIVE', style: const TextStyle(fontSize: 9)),
                      backgroundColor: Colors.teal.shade50,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load batches'),
    );
  }

  Widget _buildSubjectsView(ThemeData theme) {
    final subjectsAsync = ref.watch(adminSubjectsProvider(null));

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return const Center(child: Text('No courses or subjects configured yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final s = subjects[index] as Map<String, dynamic>;
            final dept = s['department'] as Map<String, dynamic>?;
            final deptName = dept?['code'] ?? dept?['name'] ?? 'General';
            final faculty = s['faculty'] as Map<String, dynamic>?;
            final facultyName = faculty != null ? '${faculty['first_name']} ${faculty['last_name']}' : 'Unassigned';
            final term = s['academic_term'] as Map<String, dynamic>?;
            final termName = term?['name'] ?? 'Term ${s['semester']}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade50,
                  child: Text(
                    s['code']?.toString().substring(0, (s['code']?.toString().length ?? 0).clamp(0, 3)) ?? 'SUB',
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                title: Text('${s['code']} - ${s['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$deptName • Sem ${s['semester']} • ${s['credits']} Credits • ${s['type'] ?? 'THEORY'} • Instructor: $facultyName ($termName)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Subject',
                      onPressed: () => _showEditSubjectDialog(context, s),
                    ),
                    Chip(
                      label: Text(s['status'] ?? 'ACTIVE', style: const TextStyle(fontSize: 9)),
                      backgroundColor: s['status'] == 'ACTIVE' ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load courses & subjects'),
    );
  }

  Widget _buildClassesView(ThemeData theme) {
    final classesAsync = ref.watch(adminClassesProvider(null));

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(child: Text('No academic classes or sections configured yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final c = classes[index] as Map<String, dynamic>;
            final dept = c['department'] as Map<String, dynamic>?;
            final deptName = dept?['code'] ?? dept?['name'] ?? 'General';
            final prog = c['program'] as Map<String, dynamic>?;
            final progCode = prog?['code'] ?? '';
            final advisor = c['class_advisor'] as Map<String, dynamic>?;
            final advisorName = advisor != null ? '${advisor['first_name']} ${advisor['last_name']}' : 'No Advisor';
            final room = c['room'] as Map<String, dynamic>?;
            final roomInfo = room != null ? 'Room: ${room['code']} (${room['building'] ?? ''})' : 'Room: TBD';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade50,
                  child: Text(c['section'] ?? 'A', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                ),
                title: Text('${c['name']} (Section ${c['section']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$deptName $progCode • Year ${c['year_of_study']} • Sem ${c['semester']} • Advisor: $advisorName • $roomInfo'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Class',
                      onPressed: () => _showEditClassDialog(context, c),
                    ),
                    Chip(
                      label: Text(c['is_active'] == true ? 'ACTIVE' : 'INACTIVE', style: const TextStyle(fontSize: 9)),
                      backgroundColor: c['is_active'] == true ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load academic classes'),
    );
  }

  Widget _buildRoomsView(ThemeData theme) {
    final roomsAsync = ref.watch(adminRoomsProvider(null));

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Center(child: Text('No physical rooms or venues configured yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final r = rooms[index] as Map<String, dynamic>;
            final building = r['building'] ?? 'Main Block';
            final floor = r['floor'] != null ? 'Floor ${r['floor']}' : '';
            final capacity = r['capacity'] ?? 60;
            final roomType = r['room_type'] ?? 'LECTURE_HALL';
            final isActive = r['is_active'] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.meeting_room, color: Colors.teal, size: 20),
                ),
                title: Text('${r['code']} - ${r['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$building • $floor • Capacity: $capacity • Type: $roomType'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Room',
                      onPressed: () => _showEditRoomDialog(context, r),
                    ),
                    Chip(
                      label: Text(isActive ? 'AVAILABLE' : 'MAINTENANCE', style: const TextStyle(fontSize: 9)),
                      backgroundColor: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load rooms'),
    );
  }

  Widget _buildTimetableView(ThemeData theme) {
    final schedulesAsync = ref.watch(adminSchedulesProvider(null));

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return const Center(child: Text('No timetable slots scheduled yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final s = schedules[index] as Map<String, dynamic>;
            final faculty = s['faculty'] as Map<String, dynamic>?;
            final facultyName = faculty != null ? '${faculty['first_name']} ${faculty['last_name']}' : 'Faculty';
            final room = s['room'] as Map<String, dynamic>?;
            final roomInfo = room != null ? 'Room: ${room['code']}' : 'Room: Unassigned';
            final cls = s['class'] as Map<String, dynamic>?;
            final classInfo = cls != null ? 'Class: ${cls['name']} (${cls['section']})' : '';
            final subjectTitle = s['subject_code'] != null ? '${s['subject_code']} - ${s['subject_name']}' : (s['topic'] ?? 'Session');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s['day_of_week']?.toString().substring(0, 3) ?? 'DAY',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                      Text('${s['start_time']}', style: const TextStyle(fontSize: 9, color: Colors.black87)),
                    ],
                  ),
                ),
                title: Text(subjectTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s['start_time']} - ${s['end_time']} • $facultyName • $roomInfo ${classInfo.isNotEmpty ? '• $classInfo' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Slot',
                      onPressed: () => _showEditScheduleDialog(context, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Cancel slot',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Timetable Slot'),
                            content: const Text('Are you sure you want to remove this schedule slot?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref.read(adminRemoteDataSourceProvider).deleteSchedule(s['id'].toString());
                            ref.invalidate(adminSchedulesProvider(null));
                            ref.invalidate(adminAuditReportsProvider);
                            messenger.showSnackBar(const SnackBar(content: Text('Timetable slot removed successfully')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorCard('Failed to load timetable'),
    );
  }

  // ==========================================
  // CLUBS & EVENTS TAB
  // ==========================================
  // ==========================================
  // CLUBS & EVENTS TAB (CAMPUS MODERATION & BROADCASTS)
  // ==========================================
  Widget _buildClubsAndEventsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Campus Moderation & Broadcasts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  label: const Text('Broadcast Notification'),
                  onPressed: () => _showBroadcastNotificationDialog(context),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Moderation Data',
                  onPressed: () {
                    ref.invalidate(pendingClubsProvider);
                    ref.invalidate(adminModerationEventsProvider);
                    ref.invalidate(adminModerationPostsProvider);
                    ref.invalidate(adminMetricsProvider);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ModerationSection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ModerationSection.clubs,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Club Proposals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                icon: Icon(Icons.groups_outlined, size: 18),
              ),
              ButtonSegment(
                value: ModerationSection.events,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Events', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                icon: Icon(Icons.event_outlined, size: 18),
              ),
              ButtonSegment(
                value: ModerationSection.posts,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Campus Posts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                icon: Icon(Icons.forum_outlined, size: 18),
              ),
            ],
            selected: {_moderationSection},
            onSelectionChanged: (set) => setState(() => _moderationSection = set.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_moderationSection == ModerationSection.clubs)
          _buildClubApprovalsSection(theme)
        else if (_moderationSection == ModerationSection.events)
          _buildEventModerationSection(theme)
        else
          _buildPostModerationSection(theme),
      ],
    );
  }

  Widget _buildClubApprovalsSection(ThemeData theme) {
    final pendingClubsAsync = ref.watch(pendingClubsProvider);
    final approvedClubsAsync = ref.watch(approvedClubsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tabs: Pending Proposals vs Active Clubs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ClubModerationSubSection>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ClubModerationSubSection.pending,
                label: Text(
                  'Pending Proposals (${pendingClubsAsync.valueOrNull?.length ?? 0})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.pending_actions, size: 16),
              ),
              ButtonSegment(
                value: ClubModerationSubSection.active,
                label: Text(
                  'Active Clubs (${approvedClubsAsync.valueOrNull?.length ?? 0})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.verified, size: 16),
              ),
            ],
            selected: {_clubSubSection},
            onSelectionChanged: (set) => setState(() => _clubSubSection = set.first),
          ),
        ),
        const SizedBox(height: 14),
        if (_clubSubSection == ClubModerationSubSection.pending)
          pendingClubsAsync.when(
            data: (clubs) {
              if (clubs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.verified_outlined, size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            'No pending club requests to approve!',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: clubs.map((club) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showClubDetailDialog(context, club, isPending: true),
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber,
                        backgroundImage: club.logoUrl != null && club.logoUrl!.isNotEmpty
                            ? NetworkImage(ApiEndpoints.resolveUrl(club.logoUrl!))
                            : null,
                        child: club.logoUrl == null || club.logoUrl!.isEmpty
                            ? const Icon(Icons.groups, color: Colors.white)
                            : null,
                      ),
                      title: Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: ${club.category} • Proposed by ${club.creatorName ?? "Student"}'),
                          if (club.description != null && club.description!.isNotEmpty)
                            Text(
                              club.description!.length > 90 ? '${club.description!.substring(0, 90)}...' : club.description!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            'Tap to view proposal details',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            tooltip: 'Approve Club',
                            onPressed: () => _approveClub(context, club),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                            tooltip: 'Reject Club',
                            onPressed: () => _promptRejectClub(context, club),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading pending clubs: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          )
        else
          approvedClubsAsync.when(
            data: (clubs) {
              if (clubs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.groups_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No active clubs in CampusHub yet.',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: clubs.map((club) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showClubDetailDialog(context, club, isPending: false),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: club.logoUrl != null && club.logoUrl!.isNotEmpty
                            ? NetworkImage(ApiEndpoints.resolveUrl(club.logoUrl!))
                            : null,
                        child: club.logoUrl == null || club.logoUrl!.isEmpty
                            ? const Icon(Icons.groups)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: ${club.category} • ${club.memberCount} members'),
                          if (club.creatorName != null)
                            Text('Created by: ${club.creatorName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'View Club Page',
                        onPressed: () => context.push('/clubs/${club.id}'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading active clubs: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
      ],
    );
  }

  void _showClubDetailDialog(BuildContext context, Club club, {required bool isPending}) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: club.logoUrl != null && club.logoUrl!.isNotEmpty
                  ? NetworkImage(ApiEndpoints.resolveUrl(club.logoUrl!))
                  : null,
              child: club.logoUrl == null || club.logoUrl!.isEmpty
                  ? Text(
                      club.name.isNotEmpty ? club.name[0].toUpperCase() : 'C',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (club.status == 'APPROVED' ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          club.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: club.status == 'APPROVED' ? Colors.green : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        club.category,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                // Creator Information Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.creatorName ?? 'Student Lead',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            Text(
                              '${club.departmentName ?? club.departmentCode ?? "Campus Member"} • Proposed on ${AppDateFormatter.formatDate(club.createdAt)}',
                              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('About Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  club.description != null && club.description!.isNotEmpty
                      ? club.description!
                      : 'No detailed description provided.',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                // Scope and Statistics Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildClubMetricChip(
                      icon: club.isCrossDepartment ? Icons.public : Icons.domain,
                      label: club.isCrossDepartment ? 'Cross-Department' : 'Dept-Only',
                      theme: theme,
                    ),
                    _buildClubMetricChip(
                      icon: Icons.people_outline,
                      label: '${club.memberCount} Members',
                      theme: theme,
                    ),
                    _buildClubMetricChip(
                      icon: Icons.event_outlined,
                      label: '${club.eventCount} Events',
                      theme: theme,
                    ),
                    _buildClubMetricChip(
                      icon: Icons.forum_outlined,
                      label: '${club.postCount} Posts',
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (isPending) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
              label: const Text('Reject', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                _promptRejectClub(context, club);
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Approve Club'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.of(ctx).pop();
                _approveClub(context, club);
              },
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View Club Page'),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/clubs/${club.id}');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClubMetricChip({required IconData icon, required String label, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _approveClub(BuildContext context, Club club) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(clubsRepositoryProvider);
      await repo.verifyClub(club.id, 'APPROVED');
      ref.invalidate(pendingClubsProvider);
      ref.invalidate(approvedClubsProvider);
      ref.invalidate(adminMetricsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text("Approved '${club.name}' successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _promptRejectClub(BuildContext context, Club club) async {
    final textController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject "${club.name}"'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Incomplete charter or duplicate club',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Proposal'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final repo = ref.read(clubsRepositoryProvider);
        final reason = textController.text.trim().isNotEmpty ? textController.text.trim() : 'Admin declined proposal';
        await repo.verifyClub(club.id, 'REJECTED', rejectionReason: reason);
        ref.invalidate(pendingClubsProvider);
        ref.invalidate(approvedClubsProvider);
        ref.invalidate(adminMetricsProvider);
        messenger.showSnackBar(
          SnackBar(content: Text("Rejected '${club.name}'."), backgroundColor: Colors.red),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEventModerationSection(ThemeData theme) {
    final eventsAsync = ref.watch(adminModerationEventsProvider(null));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 48, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'No campus events currently scheduled.',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: events.map((event) {
            final id = event['id']?.toString() ?? '';
            final title = event['title']?.toString() ?? 'Untitled Event';
            final scope = event['scope']?.toString() ?? 'COLLEGE';
            final category = event['category']?.toString() ?? 'General';
            final venue = event['venue']?.toString() ?? 'TBD';
            final organizer = event['organizer'] is Map ? event['organizer'] as Map<String, dynamic> : null;
            final organizerName = organizer != null ? '${organizer['first_name'] ?? ''} ${organizer['last_name'] ?? ''}'.trim() : 'Unknown';
            final registrations = event['_count'] is Map ? event['_count']['registrations'] ?? 0 : 0;
            final startTime = event['start_time']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(Icons.event_outlined, color: Colors.purple.shade800),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(scope, style: TextStyle(fontSize: 11, color: Colors.purple.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: $category • Venue: $venue • Registrations: $registrations'),
                      Text('Organizer: $organizerName • Time: ${startTime.length >= 16 ? startTime.substring(0, 16).replaceAll('T', ' ') : startTime}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove Event',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Event Removal'),
                        content: Text('Are you sure you want to remove event "$title" from campus schedules?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete Event'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(adminRemoteDataSourceProvider).deleteModerationEvent(id);
                        ref.invalidate(adminModerationEventsProvider);
                        ref.invalidate(adminMetricsProvider);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Removed "$title" successfully.'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error removing event: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading campus events: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildPostModerationSection(ThemeData theme) {
    final postsAsync = ref.watch(adminModerationPostsProvider(null));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'No campus feed posts found.',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: posts.map((post) {
            final id = post['id']?.toString() ?? '';
            final title = post['title']?.toString() ?? 'Post';
            final content = post['content']?.toString() ?? '';
            final author = post['author'] is Map ? post['author'] as Map<String, dynamic> : null;
            final authorName = author != null ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim() : 'Unknown';
            final authorAvatar = author?['avatar_url']?.toString();
            final authorRole = author != null ? author['role']?.toString() ?? '' : '';
            final commentsCount = post['_count'] is Map ? post['_count']['comments'] ?? 0 : 0;
            final likesCount = post['_count'] is Map ? post['_count']['likes'] ?? 0 : 0;
            final createdAt = post['created_at']?.toString();
            final formattedDate = createdAt != null && DateTime.tryParse(createdAt) != null
                ? AppDateFormatter.formatDateTime(DateTime.parse(createdAt))
                : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push('/posts/$id'),
                leading: CampusAvatar(
                  imageUrl: authorAvatar,
                  name: authorName,
                  radius: 20,
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (authorRole.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(authorRole, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.isNotEmpty)
                        Text(content.length > 100 ? '${content.substring(0, 100)}...' : content, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('By $authorName${formattedDate.isNotEmpty ? " • $formattedDate" : ""}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Row(
                        children: [
                          Text('Likes: $likesCount • Comments: $commentsCount', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text('• Tap to view full post', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      tooltip: 'View Full Post',
                      onPressed: () => context.push('/posts/$id'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove Post',
                      onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Post Removal'),
                        content: Text('Are you sure you want to remove post "$title" from the campus feed?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete Post'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(adminRemoteDataSourceProvider).deleteModerationPost(id);
                        ref.invalidate(adminModerationPostsProvider);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Removed "$title" successfully.'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error removing post: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading campus posts: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Future<void> _showBroadcastNotificationDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedAudience = 'ALL';
    String? selectedDeptId;
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final deptsAsync = ref.watch(adminDepartmentsProvider);

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.campaign_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Broadcast Notification',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title *',
                        hintText: 'e.g. Campus Holiday Announcement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message Body *',
                        hintText: 'Enter complete notification details...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAudience,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Campus Users', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'STUDENTS', child: Text('Students Only', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'FACULTY', child: Text('Faculty Only', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'DEPARTMENT', child: Text('Specific Department', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedAudience = val;
                            if (val != 'DEPARTMENT') selectedDeptId = null;
                          });
                        }
                      },
                    ),
                    if (selectedAudience == 'DEPARTMENT') ...[
                      const SizedBox(height: 12),
                      deptsAsync.when(
                        data: (depts) => DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedDeptId,
                          decoration: const InputDecoration(
                            labelText: 'Select Department *',
                            border: OutlineInputBorder(),
                          ),
                          items: depts.map<DropdownMenuItem<String>>((d) {
                            return DropdownMenuItem(
                              value: d['id'].toString(),
                              child: Text('${d['name']} (${d['code']})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => selectedDeptId = val),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Failed to load departments', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Broadcast'),
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();

                          if (title.isEmpty || body.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter both title and body'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          if (selectedAudience == 'DEPARTMENT' && selectedDeptId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a department'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            final res = await ref.read(adminRemoteDataSourceProvider).sendBroadcastNotification({
                              'title': title,
                              'body': body,
                              'targetAudience': selectedAudience,
                              if (selectedDeptId != null) 'departmentId': selectedDeptId,
                              'category': 'CAMPUS_ANNOUNCEMENT',
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message']?.toString() ?? 'Broadcast sent successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSending = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Broadcast failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // PLACEMENT TAB (CAREER HUB & PLACEMENT ADMINISTRATION)
  // ==========================================
  Widget _buildPlacementTab(ThemeData theme) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final officerStatsAsync = ref.watch(adminPlacementOfficerStatsProvider);
    final drivesAsync = ref.watch(adminPlacementDrivesProvider(null));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Placement Administration & Drives',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: const Text('New Drive'),
              onPressed: () => _showCreateDriveDialog(context),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Placement Data',
              onPressed: () {
                ref.invalidate(adminAnalyticsProvider);
                ref.invalidate(adminPlacementOfficerStatsProvider);
                ref.invalidate(adminPlacementDrivesProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // KPI Highlights Row
        officerStatsAsync.when(
          data: (officerStats) {
            final totalDrives = officerStats['totalDrives'] ?? 0;
            final activeDrives = officerStats['activeDrives'] ?? 0;
            final totalApps = officerStats['totalApplications'] ?? 0;
            final offeredCount = officerStats['offeredCount'] ?? 0;

            return analyticsAsync.maybeWhen(
              data: (analytics) {
                final p = (analytics['placementStats'] as Map<String, dynamic>?) ?? {};
                final rate = p['placementRate'] ?? 0;
                final avgPkg = p['averagePackage'] ?? 0;
                final highPkg = p['highestPackage'] ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard('Placement Rate', '$rate%', Icons.trending_up, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Avg Package', '$avgPkg LPA', Icons.attach_money, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Highest Package', '$highPkg LPA', Icons.workspace_premium, Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard('Total Drives', '$totalDrives', Icons.business_center_outlined, Colors.indigo)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Active Drives', '$activeDrives', Icons.bolt, Colors.amber.shade800)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Applications', '$totalApps', Icons.assignment_outlined, Colors.teal)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Offers Made', '$offeredCount', Icons.verified_user_outlined, Colors.deepPurple)),
                      ],
                    ),
                  ],
                );
              },
              orElse: () => const LinearProgressIndicator(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),
        const SizedBox(height: 14),

        // Quick Operations Bar (Matching Placement Officer Workspace)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.apartment_rounded, size: 16),
                label: const Text('Companies Directory'),
                onPressed: () => context.push('/placement/companies'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.fact_check_rounded, size: 16),
                label: const Text('Shortlists & Interviews'),
                onPressed: () => context.push('/placement/shortlist'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.pie_chart_outline_rounded, size: 16),
                label: const Text('Department Analytics'),
                onPressed: () => context.push('/placement/analytics'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.file_present_rounded, size: 16),
                label: const Text('Accreditation Reports'),
                onPressed: () => context.push('/placement/reports'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.school_outlined, size: 16),
                label: const Text('Student Directory'),
                onPressed: () => context.push('/placement/students'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Campus Placement Drives', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Drive Search Bar
        TextField(
          controller: _placementSearchController,
          decoration: InputDecoration(
            hintText: 'Search drives by company, role, location...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _placementSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _placementSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'ONGOING', 'UPCOMING', 'COMPLETED'].map((status) {
              final isSelected = _selectedPlacementStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedPlacementStatus = status),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        drivesAsync.when(
          data: (drives) {
            final query = _placementSearchController.text.toLowerCase().trim();
            final filteredDrives = drives.where((drive) {
              final status = drive['status']?.toString().toUpperCase() ?? '';
              if (_selectedPlacementStatus != 'ALL' && status != _selectedPlacementStatus) {
                return false;
              }
              if (query.isNotEmpty) {
                final company = (drive['company_name']?.toString() ?? '').toLowerCase();
                final role = (drive['role_title']?.toString() ?? '').toLowerCase();
                final loc = (drive['location']?.toString() ?? '').toLowerCase();
                if (!company.contains(query) && !role.contains(query) && !loc.contains(query)) {
                  return false;
                }
              }
              return true;
            }).toList();

            if (filteredDrives.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.work_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty || _selectedPlacementStatus != 'ALL'
                              ? 'No placement drives match the selected filters.'
                              : 'No campus placement drives created yet.',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        if (query.isEmpty && _selectedPlacementStatus == 'ALL')
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Placement Drive'),
                            onPressed: () => _showCreateDriveDialog(context),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: filteredDrives.map((drive) {
                final driveId = drive['id']?.toString() ?? '';
                final company = drive['company_name']?.toString() ?? 'Company';
                final role = drive['role_title']?.toString() ?? 'Role';
                final pkg = drive['package_ctc']?.toString() ?? 'Undisclosed';
                final loc = drive['location']?.toString() ?? 'On-campus';
                final minCgpa = drive['min_cgpa'] ?? 0.0;
                final status = drive['status']?.toString() ?? 'UPCOMING';
                final appsCount = drive['_count'] is Map ? drive['_count']['applications'] ?? 0 : 0;
                final deadline = drive['deadline']?.toString() ?? '';

                Color statusColor = Colors.blue;
                if (status == 'ONGOING') statusColor = Colors.green;
                if (status == 'COMPLETED') statusColor = Colors.grey;
                if (status == 'CANCELLED') statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (driveId.isNotEmpty) {
                        context.push('/placement/drives/$driveId');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.indigo.shade50,
                                child: Icon(Icons.business_rounded, color: Colors.indigo.shade700, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor.withAlpha(120)),
                                ),
                                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.payments_outlined, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(pkg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(loc, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.grade_outlined, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text('Min CGPA: $minCgpa', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deadline: ${deadline.length >= 10 ? deadline.substring(0, 10) : deadline}',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.people_alt_outlined, size: 15),
                                    label: Text('Applicants ($appsCount)'),
                                    onPressed: () => _showDriveApplicationsModal(context, drive),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.visibility_outlined, size: 15),
                                    label: const Text('View Drive'),
                                    onPressed: () {
                                      if (driveId.isNotEmpty) {
                                        context.push('/placement/drives/$driveId');
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (err, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading drives: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDriveDialog(BuildContext context) async {
    final companyController = TextEditingController();
    final roleController = TextEditingController();
    final packageController = TextEditingController(text: '12 LPA');
    final locationController = TextEditingController(text: 'Bangalore / Hybrid');
    final cgpaController = TextEditingController(text: '7.0');
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));
    String selectedStatus = 'UPCOMING';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_business_rounded, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Create Placement Drive',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Role Title *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: packageController,
                      decoration: const InputDecoration(labelText: 'Package CTC', hintText: 'e.g. 14 LPA', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Hyderabad / On-site', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cgpaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Minimum CGPA (0.0 - 10.0)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Drive Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'UPCOMING', child: Text('UPCOMING')),
                        DropdownMenuItem(value: 'ONGOING', child: Text('ONGOING')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedStatus = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                      title: const Text('Application Deadline'),
                      subtitle: Text('${selectedDeadline.year}-${selectedDeadline.month.toString().padLeft(2, '0')}-${selectedDeadline.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.calendar_month_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDeadline = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final company = companyController.text.trim();
                          final role = roleController.text.trim();
                          if (company.isEmpty || role.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Company name and role are required'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            await ref.read(adminRemoteDataSourceProvider).createPlacementDrive({
                              'company_name': company,
                              'role_title': role,
                              'package_ctc': packageController.text.trim(),
                              'location': locationController.text.trim(),
                              'min_cgpa': double.tryParse(cgpaController.text.trim()) ?? 0.0,
                              'status': selectedStatus,
                              'deadline': selectedDeadline.toUtc().toIso8601String(),
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            ref.invalidate(adminPlacementDrivesProvider);
                            ref.invalidate(adminPlacementOfficerStatsProvider);
                            messenger.showSnackBar(
                              SnackBar(content: Text("Drive for '$company' created successfully!"), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to create drive: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Drive'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDriveApplicationsModal(BuildContext context, Map<String, dynamic> drive) {
    final driveId = drive['id']?.toString() ?? '';
    final company = drive['company_name']?.toString() ?? 'Drive';
    final role = drive['role_title']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return Consumer(
          builder: (context, ref, _) {
            final detailsAsync = ref.watch(adminPlacementDriveDetailsProvider(driveId));

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$company - $role', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Applicant Evaluation & Status Oversight', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: detailsAsync.when(
                      data: (data) {
                        final apps = (data['applications'] as List<dynamic>?) ?? [];
                        if (apps.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No student applications submitted yet for this drive.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: apps.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final app = apps[idx] as Map<String, dynamic>;
                            final appId = app['id']?.toString() ?? '';
                            final student = app['student'] as Map<String, dynamic>?;
                            final studentName = student != null
                                ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim()
                                : 'Student';
                            final studentEmail = student?['email']?.toString() ?? '';
                            final dept = student?['department'] is Map ? student!['department']['name']?.toString() ?? '' : '';
                            final appStatus = app['status']?.toString() ?? 'APPLIED';

                            Color chipColor = Colors.blue;
                            if (appStatus == 'SHORTLISTED') chipColor = Colors.orange;
                            if (appStatus == 'INTERVIEW_SCHEDULED') chipColor = Colors.purple;
                            if (appStatus == 'OFFERED') chipColor = Colors.green;
                            if (appStatus == 'REJECTED') chipColor = Colors.red;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: chipColor.withAlpha(40),
                                child: Text(studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S', style: TextStyle(color: chipColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: chipColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: chipColor.withAlpha(120)),
                                    ),
                                    child: Text(appStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: chipColor)),
                                  ),
                                ],
                              ),
                              subtitle: Text('$studentEmail ${dept.isNotEmpty ? "• $dept" : ""}'),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Update Applicant Status',
                                icon: const Icon(Icons.more_vert),
                                onSelected: (newStatus) async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await ref.read(adminRemoteDataSourceProvider).updatePlacementApplicationStatus(appId, {
                                      'status': newStatus,
                                    });
                                    ref.invalidate(adminPlacementDriveDetailsProvider(driveId));
                                    ref.invalidate(adminPlacementOfficerStatsProvider);
                                    ref.invalidate(adminPlacementDrivesProvider);
                                    messenger.showSnackBar(
                                      SnackBar(content: Text("Updated $studentName to $newStatus"), backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(value: 'SHORTLISTED', child: Text('Mark as SHORTLISTED')),
                                  PopupMenuItem(value: 'INTERVIEW_SCHEDULED', child: Text('Mark as INTERVIEW_SCHEDULED')),
                                  PopupMenuItem(value: 'OFFERED', child: Text('Mark as OFFERED')),
                                  PopupMenuItem(value: 'REJECTED', child: Text('Mark as REJECTED')),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading applicants: $err', style: const TextStyle(color: Colors.red))),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ANALYTICS TAB
  // ==========================================
  Widget _buildAnalyticsTab(ThemeData theme) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final monitoringAsync = ref.watch(adminMonitoringMetricsProvider(null));
    final sessionsAsync = ref.watch(adminMonitoringAttendanceProvider(null));
    final assignmentsAsync = ref.watch(adminMonitoringAssignmentsProvider(null));
    final assessmentsAsync = ref.watch(adminMonitoringAssessmentsProvider(null));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Academic Monitoring & Campus Analytics',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(adminAnalyticsProvider);
                ref.invalidate(adminMonitoringMetricsProvider(null));
                ref.invalidate(adminMonitoringAttendanceProvider(null));
                ref.invalidate(adminMonitoringAssignmentsProvider(null));
                ref.invalidate(adminMonitoringAssessmentsProvider(null));
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 1. Academic Monitoring Metrics Cards
        monitoringAsync.when(
          data: (metrics) {
            final totalSessions = metrics['totalAttendanceSessions'] ?? 0;
            final attRate = metrics['averageAttendanceRate'] ?? 0;
            final totalAssign = metrics['totalAssignments'] ?? 0;
            final totalSubs = metrics['totalSubmissions'] ?? 0;
            final totalAssess = metrics['totalAssessments'] ?? 0;
            final avgScore = metrics['averageAssessmentScore'] ?? 0;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0.5,
                        color: theme.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.fact_check_outlined, color: Colors.green),
                              const SizedBox(height: 8),
                              Text('$attRate%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 2),
                              Text(
                                'Attendance Rate ($totalSessions Sessions)',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 0.5,
                        color: theme.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.assignment_outlined, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text('$totalAssign', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 2),
                              Text(
                                'Assignments ($totalSubs Submissions)',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0.5,
                        color: theme.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.quiz_outlined, color: Colors.purple),
                              const SizedBox(height: 8),
                              Text('$totalAssess', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple)),
                              const SizedBox(height: 2),
                              Text(
                                'Assessments ($avgScore Avg Score)',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 0.5,
                        color: theme.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.analytics_outlined, color: Colors.amber),
                              const SizedBox(height: 8),
                              analyticsAsync.when(
                                data: (data) {
                                  final eng = (data['engagementStats'] as Map<String, dynamic>?) ?? {};
                                  final activeDaily = eng['activeDailyUsers'] ?? 0;
                                  return Text('$activeDaily', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber));
                                },
                                loading: () => const Text('...'),
                                error: (_, __) => const Text('0'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daily Active Users',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),
        Text('Attendance Sessions Conducted', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No attendance sessions recorded yet.', style: TextStyle(color: Colors.grey))),
                ),
              );
            }
            return Column(
              children: sessions.take(5).map((s) {
                final sub = s['subject'] as Map<String, dynamic>?;
                final subCode = sub?['code'] ?? 'SUB';
                final faculty = s['faculty'] as Map<String, dynamic>?;
                final facName = faculty != null ? '${faculty['first_name']} ${faculty['last_name']}' : 'Faculty';
                final pres = s['present_count'] ?? 0;
                final tot = s['total_students'] ?? 0;
                final pct = tot > 0 ? ((pres / tot) * 100).toStringAsFixed(1) : '0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: Text('$pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    title: Text(
                      '$subCode: ${s['topic'] ?? 'Regular Lecture'}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Date: ${s['session_date']?.toString().split('T').first ?? ''} • $pres/$tot Present • Instructor: $facName',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                        softWrap: true,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorCard('Failed to load attendance sessions'),
        ),

        const SizedBox(height: 24),
        Text('Course Assignments Published', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('No course assignments published yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                ),
              );
            }
            return Column(
              children: assignments.take(5).map((a) {
                final sub = a['subject'] as Map<String, dynamic>?;
                final subCode = sub?['code'] ?? 'SUB';
                final subsCount = (a['_count'] as Map?)?['submissions'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: const Icon(Icons.assignment, color: Colors.blue, size: 18),
                    ),
                    title: Text(
                      '$subCode: ${a['title']}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Due: ${a['due_at']?.toString().split('T').first ?? ''} • Max: ${a['max_marks']} marks • $subsCount submissions',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                        softWrap: true,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorCard('Failed to load assignments'),
        ),

        const SizedBox(height: 24),
        Text('Continuous Assessments & Exams', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        assessmentsAsync.when(
          data: (assessments) {
            if (assessments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('No assessments or exams recorded yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                ),
              );
            }
            return Column(
              children: assessments.take(5).map((e) {
                final sub = e['subject'] as Map<String, dynamic>?;
                final subCode = sub?['code'] ?? 'SUB';
                final evalCount = (e['_count'] as Map?)?['results'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withValues(alpha: 0.15),
                      child: const Icon(Icons.quiz, color: Colors.purple, size: 18),
                    ),
                    title: Text(
                      '$subCode: ${e['title']} (${e['assessment_type']})',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      softWrap: true,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Max: ${e['total_marks']} • Pass: ${e['passing_marks']} • $evalCount Graded Results',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                        softWrap: true,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorCard('Failed to load assessments'),
        ),
      ],
    );
  }

  // ==========================================
  // SETTINGS & GOVERNANCE TAB (PHASE 9)
  // ==========================================
  Widget _buildSettingsAndGovernanceTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SettingsSection>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: SettingsSection.profile,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Institutional Profile', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    icon: Icon(Icons.account_balance_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: SettingsSection.adminProfile,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Staff Identity', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    icon: Icon(Icons.badge_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: SettingsSection.auditLogs,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Audit Logs & CSV', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    icon: Icon(Icons.receipt_long_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: SettingsSection.roles,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Role Governance', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    icon: Icon(Icons.shield_outlined, size: 18),
                  ),
                ],
                selected: {_settingsSection},
                onSelectionChanged: (set) {
                  setState(() => _settingsSection = set.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_settingsSection == SettingsSection.profile)
            _buildInstitutionalProfile(theme)
          else if (_settingsSection == SettingsSection.adminProfile)
            _buildStaffIdentityGovernance(theme)
          else if (_settingsSection == SettingsSection.auditLogs)
            _buildAuditLogExplorer(theme)
          else
            _buildRoleGovernance(theme),
        ],
      ),
    );
  }

  Widget _buildStaffFilterBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildStaffIdentityGovernance(ThemeData theme) {
    final usersAsync = ref.watch(adminUsersProvider(null));

    return usersAsync.when(
      data: (users) {
        final staffUsers = users.where((u) {
          final role = (u['role'] ?? '').toString().toUpperCase();
          return role != 'STUDENT' && role.isNotEmpty;
        }).toList();

        final facultyCount = staffUsers.where((u) => u['role'] == 'FACULTY').length;
        final deptAdminCount = staffUsers.where((u) => u['role'] == 'DEPT_ADMIN').length;
        final placementCount = staffUsers.where((u) => u['role'] == 'PLACEMENT').length;
        final adminCount = staffUsers.where((u) => u['role'] == 'ADMIN').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Staff Identity & Institutional Directory',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage institutional staff profiles, access scopes, and faculty identity governance.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStaffFilterBadge('All Staff: ${staffUsers.length}', Colors.blueGrey),
                        _buildStaffFilterBadge('Faculty: $facultyCount', Colors.blue),
                        _buildStaffFilterBadge('HOD / Dept Admin: $deptAdminCount', Colors.purple),
                        _buildStaffFilterBadge('Placement: $placementCount', Colors.orange),
                        _buildStaffFilterBadge('Admin: $adminCount', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (staffUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No staff members registered in directory.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...staffUsers.map((u) {
                final firstName = u['first_name'] ?? '';
                final lastName = u['last_name'] ?? '';
                final name = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Staff Member';
                final role = (u['role'] ?? 'STAFF').toString().toUpperCase();
                final dept = u['department']?['name'] ?? u['department']?['code'] ?? 'Campus-wide';
                final email = u['email'] ?? 'No email';

                final rawAvatar = u['avatar_url'] ?? u['avatarUrl'];
                final resolvedAvatar = rawAvatar != null && rawAvatar.toString().trim().isNotEmpty
                    ? ApiEndpoints.resolveUrl(rawAvatar.toString().trim())
                    : null;

                Color roleColor = Colors.blue;
                if (role == 'DEPT_ADMIN') roleColor = Colors.purple;
                if (role == 'PLACEMENT') roleColor = Colors.orange;
                if (role == 'ADMIN') roleColor = Colors.green;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CampusAvatar(
                          imageUrl: resolvedAvatar,
                          name: name,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dept,
                                style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Staff Permissions',
                          onPressed: () => _showEditUserDialog(context, u),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Text('Failed to load staff identity: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildInstitutionalProfile(ThemeData theme) {
    final collegeAsync = ref.watch(adminCollegeSettingsProvider);

    return collegeAsync.when(
      data: (college) {
        if (college.isEmpty) {
          return const Center(
            child: Text('No institutional profile found.', style: TextStyle(color: Colors.grey)),
          );
        }

        final name = college['name'] ?? 'Institution';
        final code = college['code'] ?? 'N/A';
        final domain = college['domain'] ?? 'N/A';
        final address = college['address'] ?? 'Not specified';
        final logoUrl = college['logo_url']?.toString();
        final isActive = college['is_active'] == true;
        final counts = college['_count'] as Map<String, dynamic>? ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header row: Logo on left, Status + Code chips on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: (logoUrl != null && logoUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    ApiEndpoints.resolveUrl(logoUrl),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const GceeLogo(size: 38),
                                  ),
                                )
                              : const GceeLogo(size: 38),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: isActive ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'ACTIVE INSTITUTION' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Code: $code',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Full-width, unconstrained college name for clean, crisp typography
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Details & Metadata
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Domain: $domain',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              address,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditCollegeProfileDialog(context, college),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Institutional Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Institutional Scale & Active Footprint',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildKpiCard('Departments', '${counts['departments'] ?? 0}', Icons.domain, Colors.teal, onTap: () => _tabController.animateTo(2)),
                _buildKpiCard('Enrolled Users', '${counts['users'] ?? 0}', Icons.people, Colors.indigo, onTap: () => _tabController.animateTo(1)),
                _buildKpiCard('Academic Programs', '${counts['academic_programs'] ?? 0}', Icons.school, Colors.blue, onTap: () => _tabController.animateTo(3)),
                _buildKpiCard('Class Sections', '${counts['academic_classes'] ?? 0}', Icons.meeting_room, Colors.deepPurple, onTap: () => _tabController.animateTo(3)),
                _buildKpiCard('Rooms & Venues', '${counts['rooms'] ?? 0}', Icons.room, Colors.cyan, onTap: () => _tabController.animateTo(3)),
                _buildKpiCard('Placement Drives', '${counts['drives'] ?? 0}', Icons.work, Colors.orange, onTap: () => _tabController.animateTo(5)),
                _buildKpiCard('Campus Clubs', '${counts['clubs'] ?? 0}', Icons.groups, Colors.amber.shade800, onTap: () => _tabController.animateTo(4)),
                _buildKpiCard('Approved Events', '${counts['events'] ?? 0}', Icons.event, Colors.purple, onTap: () => _tabController.animateTo(4)),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(
        child: Column(
          children: [
            _buildErrorCard('Error loading institutional profile: $err'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.refresh(adminCollegeSettingsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCollegeProfileDialog(BuildContext context, Map<String, dynamic> college) {
    final nameCtrl = TextEditingController(text: college['name']?.toString() ?? '');
    final domainCtrl = TextEditingController(text: college['domain']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: college['address']?.toString() ?? '');
    final logoUrlCtrl = TextEditingController(text: college['logo_url']?.toString() ?? '');
    SelectedMediaFile? pickedLogoFile;
    bool isCustomUrlExpanded = logoUrlCtrl.text.trim().isNotEmpty;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final theme = Theme.of(dialogCtx);
          final currentUrl = logoUrlCtrl.text.trim();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Institutional Profile',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Institutional Logo Section with Upload Picker
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: pickedLogoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: pickedLogoFile!.bytes != null
                                        ? Image.memory(
                                            pickedLogoFile!.bytes!,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          )
                                        : (pickedLogoFile!.path != null
                                            ? Image.file(
                                                File(pickedLogoFile!.path!),
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.school, size: 36, color: Colors.blue)),
                                  )
                                : (currentUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          ApiEndpoints.resolveUrl(currentUrl),
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const GceeLogo(size: 44),
                                        ),
                                      )
                                    : const GceeLogo(size: 44)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final file = await MediaPickerService.showMediaPickerSheet(
                                          context,
                                          title: 'Select Institutional Logo',
                                          enableCamera: true,
                                          enableGallery: true,
                                          enableVideoCamera: false,
                                          enableVideoGallery: false,
                                          enableDocuments: false,
                                        );
                                        if (file != null) {
                                          setDialogState(() {
                                            pickedLogoFile = file;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: Text(pickedLogoFile != null ? 'Change File' : 'Upload Logo'),
                              ),
                              if (pickedLogoFile != null)
                                TextButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            pickedLogoFile = null;
                                          });
                                        },
                                  child: const Text('Reset', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                isCustomUrlExpanded = !isCustomUrlExpanded;
                              });
                            },
                            child: Text(
                              isCustomUrlExpanded ? 'Hide URL Option' : 'Or enter Image URL (Optional)',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCustomUrlExpanded) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: logoUrlCtrl,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Custom Logo URL (Optional)',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'College Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: domainCtrl,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Domain (e.g. gcee.ac.in)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      enabled: !isSaving,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Campus Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = nameCtrl.text.trim();
                        final newDomain = domainCtrl.text.trim();
                        final newAddress = addressCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);

                        if (newName.isEmpty) {
                          messenger.showSnackBar(const SnackBar(content: Text('College Name cannot be empty')));
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          String finalLogoUrl = logoUrlCtrl.text.trim();

                          if (pickedLogoFile != null) {
                            final uploadResult = await ref
                                .read(mediaUploadServiceProvider)
                                .uploadSelectedFile(pickedLogoFile!);
                            finalLogoUrl = uploadResult.url;
                          }

                          await ref.read(adminRemoteDataSourceProvider).updateCollegeSettings({
                            'name': newName,
                            if (newDomain.isNotEmpty) 'domain': newDomain,
                            if (newAddress.isNotEmpty) 'address': newAddress,
                            if (finalLogoUrl.isNotEmpty) 'logoUrl': finalLogoUrl,
                          });
                          ref.invalidate(adminCollegeSettingsProvider);
                          ref.invalidate(adminAuditReportsProvider);
                          ref.invalidate(adminMetricsProvider);

                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Institutional profile updated successfully!'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to update college: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuditLogExplorer(ThemeData theme) {
    final filter = AdminAuditLogsFilter(
      action: _auditActionController.text.trim().isEmpty ? null : _auditActionController.text.trim(),
      category: _selectedAuditCategory,
    );
    final auditLogsAsync = ref.watch(adminAuditReportsFilteredProvider(filter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _auditActionController,
                        decoration: InputDecoration(
                          hintText: 'Filter by action or keyword...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _auditActionController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _auditActionController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedAuditCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        hint: const Text('All Categories', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Categories', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'ACADEMIC_SETUP', child: Text('Academic Setup', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'USER_MANAGEMENT', child: Text('User Mgmt', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'PLACEMENT', child: Text('Placement', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'MODERATION', child: Text('Moderation', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'INSTITUTIONAL_SETTINGS', child: Text('Settings', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) => setState(() => _selectedAuditCategory = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref.invalidate(adminAuditReportsFilteredProvider(filter));
                        ref.invalidate(adminAuditReportsProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _exportAuditLogsCsv(context),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export RFC-4180 CSV'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        auditLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No audit log entries found matching current filter criteria.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index] as Map<String, dynamic>;
                final action = log['action']?.toString() ?? 'ACTION';
                final category = log['category']?.toString() ?? 'SYSTEM';
                final actorName = log['actorName']?.toString() ?? 'System';
                final actorRole = log['actorRole']?.toString() ?? 'SYSTEM';
                final details = log['details']?.toString() ?? '';
                final entityType = log['entityType']?.toString() ?? '';
                final entityId = log['entityId']?.toString() ?? '';
                final timestamp = log['timestamp']?.toString() ?? '';
                final metadata = log['metadata'];

                Color actionColor = Colors.blue;
                if (action.contains('CREATE') || action.contains('ADD') || action.contains('APPROVE') || action.contains('OFFER')) {
                  actionColor = Colors.green;
                } else if (action.contains('UPDATE') || action.contains('EDIT') || action.contains('CHANGE')) {
                  actionColor = Colors.orange;
                } else if (action.contains('DELETE') || action.contains('REMOVE') || action.contains('REJECT')) {
                  actionColor = Colors.red;
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    action,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: actionColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              timestamp.length > 19 ? timestamp.substring(0, 19).replaceAll('T', ' ') : timestamp,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details.isNotEmpty ? details : '$action on $entityType ($entityId)',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'By: $actorName',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(actorRole).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    actorRole,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getRoleColor(actorRole),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (entityType.isNotEmpty)
                              Text(
                                entityType,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        if (metadata != null && metadata is Map && metadata.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              dense: true,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.all(8),
                              title: Text('Metadata Payload', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                                  ),
                                  child: SelectableText(
                                    metadata.toString(),
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (err, _) => _buildErrorCard('Failed to load audit trail: $err'),
        ),
      ],
    );
  }

  Future<void> _exportAuditLogsCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    try {
      final actionFilter = _auditActionController.text.trim().isEmpty ? null : _auditActionController.text.trim();
      final categoryFilter = _selectedAuditCategory;
      final csvData = await ref.read(adminRemoteDataSourceProvider).getAuditReportsCsv(
        action: actionFilter,
        category: categoryFilter,
      );

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_chart_outlined, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Audit Trail CSV Export',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: RFC-4180 Compliant CSV • ${csvData.split('\n').where((l) => l.trim().isNotEmpty).length - 1} records',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () async {
                        try {
                          final dir = await getApplicationDocumentsDirectory();
                          final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
                          final fileName = 'campushub_audit_logs_$timestamp.csv';
                          final file = File('${dir.path}/$fileName');
                          await file.writeAsString(csvData);

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('CSV downloaded: $fileName'),
                              backgroundColor: Colors.teal.shade700,
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'OPEN',
                                textColor: Colors.white,
                                onPressed: () {
                                  OpenFilex.open(file.path);
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Download error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download CSV File'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: csvData));
                        messenger.showSnackBar(
                          const SnackBar(content: Text('CSV copied to clipboard!'), backgroundColor: Colors.teal),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        csvData.isEmpty ? 'No records returned for export.' : csvData,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: theme.brightness == Brightness.dark ? Colors.tealAccent.shade200 : Colors.teal.shade900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate CSV: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRoleGovernance(ThemeData theme) {
    const roles = [
      {
        'role': 'ADMIN',
        'desc': 'Institution-level authority for Government College of Engineering, Erode: manage users, students, faculty, placement accounts, departments, academic years, classes, timetable, governance, and audit trails.',
        'perms': ['Institution-Level Oversight', 'User Roster Provisioning', 'Academic Structure CRUD', 'Moderation & Broadcasts', 'Audit Trail Export'],
      },
      {
        'role': 'FACULTY',
        'desc': 'Faculty academic workspace: course delivery, attendance logging, session schedules, assignments, assessments, and subject resources.',
        'perms': ['Attendance Marking', 'Assessments & Grading', 'Course Material Uploads', 'Assigned Students Oversight'],
      },
      {
        'role': 'PLACEMENT',
        'desc': 'Placement Officer workspace: manage recruitment drives, partner companies, student eligibility criteria, interview pipelines, and placement results.',
        'perms': ['Placement Drive Management', 'Corporate Company Profiles', 'Student Shortlisting & Eligibility', 'Offer Tracking & Analytics'],
      },
      {
        'role': 'DEPT_ADMIN',
        'desc': 'Department-level administrator: oversee department faculty, students, academic courses, classroom assignments, and timetable scheduling.',
        'perms': ['Department-Scoped Oversight', 'Department Faculty & Student CRUD', 'Academic Classes & Timetable'],
      },
      {
        'role': 'STUDENT',
        'desc': 'Official student portal: institutional profile, enrolled subjects, timetable, attendance records, placement opportunities, and campus announcements.',
        'perms': ['Attendance Ledger', 'Placement Applications', 'Verified Clubs & Events', 'Campus Social Feed'],
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final r = roles[index];
        final roleName = r['role'] as String;
        final perms = r['perms'] as List<String>;
        final roleColor = _getRoleColor(roleName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: roleColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      roleName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: roleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['desc'] as String,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: perms.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.w500),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  Widget _buildErrorCard(String msg) {
    return Center(
      child: CampusErrorState(
        message: msg,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppColors.primaryNavy;
      case 'DEPT_ADMIN':
        return Colors.teal;
      case 'PLACEMENT':
        return AppColors.electricBlue;
      case 'FACULTY':
        return AppColors.secondaryCyan;
      case 'STUDENT':
      default:
        return AppColors.primaryBlue;
    }
  }

  // ==========================================
  // DIALOGS
  // ==========================================
  void _showAddDepartmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Department'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department Name (e.g. Computer Science) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Department Code (e.g. CSE) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              final messenger = ScaffoldMessenger.of(context);
              if (name.isEmpty || code.isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('Name and code are required')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref.read(adminRemoteDataSourceProvider).createDepartment(
                  name: name,
                  code: code,
                  description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                );
                ref.invalidate(adminDepartmentsProvider);
                ref.invalidate(adminMetricsProvider);
                ref.invalidate(adminAuditReportsProvider);
                messenger.showSnackBar(
                  SnackBar(content: Text("Department '$name' created successfully")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to create department: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDepartmentDialog(BuildContext context, Map<String, dynamic> dept) {
    final deptId = dept['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: dept['name'] ?? '');
    final codeCtrl = TextEditingController(text: dept['code'] ?? '');
    final descCtrl = TextEditingController(text: dept['description'] ?? '');
    bool isActive = dept['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Department'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Department Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Department Code *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Department'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),  actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final code = codeCtrl.text.trim().toUpperCase();
                final messenger = ScaffoldMessenger.of(context);
                if (name.isEmpty || code.isEmpty) {
                  messenger.showSnackBar(const SnackBar(content: Text('Name and code are required')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRemoteDataSourceProvider).updateDepartment(deptId, {
                    'name': name,
                    'code': code,
                    'description': descCtrl.text.trim(),
                    'isActive': isActive,
                  });
                  ref.invalidate(adminDepartmentsProvider);
                  ref.invalidate(adminAuditReportsProvider);
                  messenger.showSnackBar(
                    SnackBar(content: Text("Department '$name' updated successfully")),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update department: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDepartmentDialog(BuildContext context, Map<String, dynamic> dept) {
    final deptId = dept['id']?.toString() ?? '';
    final deptName = dept['name']?.toString() ?? 'Department';
    final deptCode = dept['code']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Delete Department',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete department '$deptName' ($deptCode)?\n\nAny users currently assigned to this department will have their department assignment unlinked. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(adminRemoteDataSourceProvider).deleteDepartment(deptId);
                ref.invalidate(adminDepartmentsProvider);
                ref.invalidate(adminMetricsProvider);
                ref.invalidate(adminAuditReportsProvider);
                messenger.showSnackBar(
                  SnackBar(content: Text("Department '$deptName' deleted successfully")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete department: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static const List<String> kCommonEngineeringBatches = [
    '2026-2030',
    '2025-2029',
    '2024-2028',
    '2023-2027',
    '2022-2026',
    '2021-2025',
    '2020-2024',
  ];

  static String calculateYearFromBatch(String batchName, [DateTime? date]) {
    final match = RegExp(r'^(\d{4})').firstMatch(batchName.trim());
    if (match == null) return '1st Year';
    final admYear = int.tryParse(match.group(1)!);
    if (admYear == null) return '1st Year';

    final now = date ?? DateTime.now();
    final acadStartYear = now.month >= 6 ? now.year : now.year - 1;
    final diff = acadStartYear - admYear + 1;

    if (diff <= 1) return '1st Year';
    if (diff == 2) return '2nd Year';
    if (diff == 3) return '3rd Year';
    if (diff == 4) return '4th Year';
    return 'Graduated';
  }

  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final regNoCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    // The normal Create User screen must NOT allow creation of ADMIN.
    // Role dropdown must contain only:
    // - Department Admin (DEPT_ADMIN)
    // - Faculty (FACULTY)
    // - Placement (PLACEMENT)
    // - Student (STUDENT)
    String selectedRole = 'STUDENT';
    String? selectedDeptId;
    String selectedBatch = '2026-2030';
    String selectedYear = calculateYearFromBatch(selectedBatch);
    String selectedStatus = 'ACTIVE';
    bool obscurePassword = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final theme = Theme.of(context);
          final isStudent = selectedRole == 'STUDENT';
          final isFaculty = selectedRole == 'FACULTY';
          final isPlacement = selectedRole == 'PLACEMENT';
          final isDeptAdmin = selectedRole == 'DEPT_ADMIN';
          final showDepartment = isStudent || isFaculty || isDeptAdmin;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.person_add_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Add New User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Selector: only Department Admin, Faculty, Placement, Student
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'DEPT_ADMIN',
                          child: Text('Department Admin', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'FACULTY',
                          child: Text('Faculty', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'PLACEMENT',
                          child: Text('Placement', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'STUDENT',
                          child: Text('Student', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedRole = val;
                                  if (selectedRole == 'PLACEMENT') {
                                    selectedDeptId = null;
                                  }
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Full Name (First and Last Name)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameCtrl,
                            enabled: !isSubmitting,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lastNameCtrl,
                            enabled: !isSubmitting,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: emailCtrl,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. user@campushub.edu',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Role-Specific Fields
                    if (showDepartment) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedDeptId,
                        decoration: InputDecoration(
                          labelText: isDeptAdmin
                              ? 'Administered Department *'
                              : 'Department *',
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                        items: [
                          ...depts.map((d) => DropdownMenuItem(
                                value: d['id']?.toString(),
                                child: Text('${d['code'] ?? ''} - ${d['name'] ?? ''}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (val) => setDialogState(() => selectedDeptId = val),
                      ),
                    ],

                    // Student-specific fields: Batch dropdown, Year, Reg No, Roll No (NO Section!)
                    if (isStudent) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedBatch,
                              decoration: const InputDecoration(
                                labelText: 'Batch *',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: kCommonEngineeringBatches.map((b) {
                                final yr = calculateYearFromBatch(b);
                                return DropdownMenuItem(
                                  value: b,
                                  child: Text('$b ($yr)', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          selectedBatch = val;
                                          selectedYear = calculateYearFromBatch(val);
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('add_year_$selectedYear'),
                              isExpanded: true,
                              initialValue: selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year *',
                                prefixIcon: Icon(Icons.timeline_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                                DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                                DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                                DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                                DropdownMenuItem(value: 'Graduated', child: Text('Graduated')),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setDialogState(() => selectedYear = val);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Year is auto-calculated based on batch (June to May cycle). Modify above for manual override.',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: regNoCtrl,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Registration Number',
                                prefixIcon: Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rollCtrl,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number',
                                prefixIcon: Icon(Icons.numbers_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Staff credentials: Password manually entered by Admin (NOT random)
                    if (isFaculty || isPlacement || isDeptAdmin) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordCtrl,
                        enabled: !isSubmitting,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                          hintText: 'Enter account password',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordCtrl,
                        enabled: !isSubmitting,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: const OutlineInputBorder(),
                          hintText: 'Re-enter password',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Account Status',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setDialogState(() => selectedStatus = val);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final firstName = firstNameCtrl.text.trim();
                        final lastName = lastNameCtrl.text.trim();

                        if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid email address')),
                          );
                          return;
                        }
                        if (firstName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('First name is required')),
                          );
                          return;
                        }
                        if (showDepartment && selectedDeptId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a department')),
                          );
                          return;
                        }
                        if (isFaculty || isPlacement || isDeptAdmin) {
                          final pass = passwordCtrl.text;
                          final confirmPass = confirmPasswordCtrl.text;
                          if (pass.isEmpty || pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            return;
                          }
                          if (pass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match')),
                            );
                            return;
                          }
                        }

                        setDialogState(() => isSubmitting = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final payload = <String, dynamic>{
                            'email': email,
                            'firstName': firstName,
                            'lastName': lastName.isNotEmpty ? lastName : (isStudent ? 'Student' : 'User'),
                            'role': selectedRole,
                            'status': selectedStatus,
                          };

                          if (selectedDeptId != null) {
                            payload['departmentId'] = selectedDeptId;
                          }

                          if (isStudent) {
                            payload['batchName'] = selectedBatch;
                            payload['year'] = selectedYear;
                            final match = RegExp(r'^(\d{4})').firstMatch(selectedBatch);
                            if (match != null) {
                              payload['admissionYear'] = int.parse(match.group(1)!);
                            }
                            int cyNum = 1;
                            if (selectedYear == '2nd Year') {
                              cyNum = 2;
                            } else if (selectedYear == '3rd Year') {
                              cyNum = 3;
                            } else if (selectedYear == '4th Year') {
                              cyNum = 4;
                            } else if (selectedYear == 'Graduated') {
                              cyNum = 5;
                            }
                            payload['currentYear'] = cyNum;
                            if (regNoCtrl.text.trim().isNotEmpty) {
                              payload['registrationNumber'] = regNoCtrl.text.trim();
                            }
                            if (rollCtrl.text.trim().isNotEmpty) {
                              payload['rollNumber'] = rollCtrl.text.trim();
                            }
                          } else {
                            payload['password'] = passwordCtrl.text;
                          }

                          await ref.read(adminRemoteDataSourceProvider).createUser(payload);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (mounted) {
                            setState(() {
                              if (_selectedRole != null && _selectedRole != selectedRole) {
                                _selectedRole = selectedRole;
                              }
                              _searchController.clear();
                            });
                            ref.invalidate(adminUsersProvider);
                            ref.invalidate(adminMetricsProvider);
                            ref.invalidate(adminAuditReportsProvider);
                          }

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('User $firstName $lastName created successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to add user: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create User'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final role = user['role']?.toString().toUpperCase() ?? 'STUDENT';
    final firstNameCtrl = TextEditingController(text: user['first_name'] ?? '');
    final lastNameCtrl = TextEditingController(text: user['last_name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final rollCtrl = TextEditingController(text: user['roll_number'] ?? '');
    final regNoCtrl = TextEditingController(
      text: user['student_profile']?['registration_number'] ?? user['registration_number'] ?? '',
    );
    final batchCtrl = TextEditingController();
    final admissionYearCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final officeRoomCtrl = TextEditingController();
    String selectedStatus = user['status']?.toString() ?? 'ACTIVE';
    String? selectedDeptId = user['department_id']?.toString() ?? (user['department']?['id']?.toString());
    String selectedYear = '1st Year';

    if (user['academic_profile'] is Map) {
      final ap = user['academic_profile'];
      batchCtrl.text = ap['batch_name']?.toString() ?? '';
      admissionYearCtrl.text = ap['admission_year']?.toString() ?? '';
      if (ap['current_year'] != null) {
        final cy = ap['current_year'];
        if (cy == 1 || cy == '1') {
          selectedYear = '1st Year';
        } else if (cy == 2 || cy == '2') {
          selectedYear = '2nd Year';
        } else if (cy == 3 || cy == '3') {
          selectedYear = '3rd Year';
        } else if (cy == 4 || cy == '4') {
          selectedYear = '4th Year';
        } else if (cy == 5 || cy == '5') {
          selectedYear = 'Graduated';
        }
      }
      if (regNoCtrl.text.isEmpty && ap['registration_number'] != null) {
        regNoCtrl.text = ap['registration_number'].toString();
      }
    }
    if (user['faculty_profile'] is Map) {
      final fp = user['faculty_profile'];
      designationCtrl.text = fp['designation']?.toString() ?? '';
      officeRoomCtrl.text = fp['office_room']?.toString() ?? '';
    }

    // Attempt to load full user details if academic or faculty fields are empty
    if ((role == 'STUDENT' && (batchCtrl.text.isEmpty || regNoCtrl.text.isEmpty)) ||
        ((role == 'FACULTY' || role == 'PLACEMENT') && designationCtrl.text.isEmpty)) {
      try {
        final fullUser = await ref.read(adminRemoteDataSourceProvider).getUserById(userId);
        if (fullUser.isNotEmpty) {
          if (fullUser['academic_profile'] is Map) {
            final ap = fullUser['academic_profile'];
            if (batchCtrl.text.isEmpty) batchCtrl.text = ap['batch_name']?.toString() ?? '';
            if (admissionYearCtrl.text.isEmpty) admissionYearCtrl.text = ap['admission_year']?.toString() ?? '';
            if (ap['current_year'] != null) {
              final cy = ap['current_year'];
              if (cy == 1 || cy == '1') {
                selectedYear = '1st Year';
              } else if (cy == 2 || cy == '2') {
                selectedYear = '2nd Year';
              } else if (cy == 3 || cy == '3') {
                selectedYear = '3rd Year';
              } else if (cy == 4 || cy == '4') {
                selectedYear = '4th Year';
              } else if (cy == 5 || cy == '5') {
                selectedYear = 'Graduated';
              }
            }
            if (regNoCtrl.text.isEmpty && ap['registration_number'] != null) {
              regNoCtrl.text = ap['registration_number'].toString();
            }
          }
          if (fullUser['student_profile'] is Map && regNoCtrl.text.isEmpty) {
            regNoCtrl.text = fullUser['student_profile']['registration_number']?.toString() ?? '';
          }
          if (fullUser['faculty_profile'] is Map) {
            final fp = fullUser['faculty_profile'];
            if (designationCtrl.text.isEmpty) designationCtrl.text = fp['designation']?.toString() ?? '';
            if (officeRoomCtrl.text.isEmpty) officeRoomCtrl.text = fp['office_room']?.toString() ?? '';
          }
          if (selectedDeptId == null && fullUser['department_id'] != null) {
            selectedDeptId = fullUser['department_id']?.toString();
          }
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    String selectedBatch = batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : '2026-2030';
    final batchOptions = List<String>.from(kCommonEngineeringBatches);
    if (!batchOptions.contains(selectedBatch)) {
      batchOptions.insert(0, selectedBatch);
    }
    if (batchCtrl.text.trim().isEmpty) {
      batchCtrl.text = selectedBatch;
    }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final theme = Theme.of(context);
          final screenWidth = MediaQuery.of(context).size.width;
          final isWide = screenWidth >= 600;
          final dialogWidth = isWide ? 560.0 : (screenWidth * 0.92).clamp(280.0, 560.0);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit User Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(role),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Personal Details
                        Text(
                          'PERSONAL INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: firstNameCtrl,
                                  enabled: !isSaving,
                                  decoration: InputDecoration(
                                    labelText: 'First Name *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: lastNameCtrl,
                                  enabled: !isSaving,
                                  decoration: InputDecoration(
                                    labelText: 'Last Name',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextField(
                            controller: firstNameCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: lastNameCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailCtrl,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            prefixIcon: const Icon(Icons.email_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneCtrl,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Account Status',
                            prefixIcon: const Icon(Icons.toggle_on_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                            DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                            DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
                          ],
                          onChanged: isSaving ? null : (val) {
                            if (val != null) setDialogState(() => selectedStatus = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // SECTION 2: Role-Specific Details
                        Text(
                          '$role DETAILS & ACADEMICS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // STUDENT FIELDS (NO SECTION)
                        if (role == 'STUDENT') ...[
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedDeptId,
                            decoration: InputDecoration(
                              labelText: 'Department *',
                              prefixIcon: const Icon(Icons.business_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                              ...depts.map((d) => DropdownMenuItem(
                                    value: d['id'].toString(),
                                    child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: isSaving ? null : (val) => setDialogState(() => selectedDeptId = val),
                          ),
                          const SizedBox(height: 16),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('edit_batch_wide_$selectedBatch'),
                                    isExpanded: true,
                                    initialValue: selectedBatch,
                                    decoration: InputDecoration(
                                      labelText: 'Batch *',
                                      prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    items: batchOptions.map((b) {
                                      final yr = calculateYearFromBatch(b);
                                      return DropdownMenuItem(
                                        value: b,
                                        child: Text('$b ($yr)', overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: isSaving
                                        ? null
                                        : (val) {
                                            if (val != null) {
                                              setDialogState(() {
                                                selectedBatch = val;
                                                batchCtrl.text = val;
                                                selectedYear = calculateYearFromBatch(val);
                                                final match = RegExp(r'^(\d{4})').firstMatch(val);
                                                if (match != null) {
                                                  admissionYearCtrl.text = match.group(1)!;
                                                }
                                              });
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('edit_year_wide_$selectedYear'),
                                    isExpanded: true,
                                    initialValue: selectedYear,
                                    decoration: InputDecoration(
                                      labelText: 'Year *',
                                      prefixIcon: const Icon(Icons.timeline_outlined, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                                      DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                                      DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                                      DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                                      DropdownMenuItem(value: 'Graduated', child: Text('Graduated')),
                                    ],
                                    onChanged: isSaving
                                        ? null
                                        : (val) {
                                            if (val != null) setDialogState(() => selectedYear = val);
                                          },
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            DropdownButtonFormField<String>(
                              key: ValueKey('edit_batch_narrow_$selectedBatch'),
                              isExpanded: true,
                              initialValue: selectedBatch,
                              decoration: InputDecoration(
                                labelText: 'Batch *',
                                prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: batchOptions.map((b) {
                                final yr = calculateYearFromBatch(b);
                                return DropdownMenuItem(
                                  value: b,
                                  child: Text('$b ($yr)', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: isSaving
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          selectedBatch = val;
                                          batchCtrl.text = val;
                                          selectedYear = calculateYearFromBatch(val);
                                          final match = RegExp(r'^(\d{4})').firstMatch(val);
                                          if (match != null) {
                                            admissionYearCtrl.text = match.group(1)!;
                                          }
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: ValueKey('edit_year_narrow_$selectedYear'),
                              isExpanded: true,
                              initialValue: selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year *',
                                prefixIcon: const Icon(Icons.timeline_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                                DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                                DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                                DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                                DropdownMenuItem(value: 'Graduated', child: Text('Graduated')),
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (val) {
                                      if (val != null) setDialogState(() => selectedYear = val);
                                    },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Year is auto-calculated following Anna University June-to-May schedule. Modify only for administrative correction/override.',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: regNoCtrl,
                                    enabled: !isSaving,
                                    decoration: InputDecoration(
                                      labelText: 'Registration Number',
                                      prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: rollCtrl,
                                    enabled: !isSaving,
                                    decoration: InputDecoration(
                                      labelText: 'Roll Number',
                                      prefixIcon: const Icon(Icons.numbers_outlined, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextField(
                              controller: regNoCtrl,
                              enabled: !isSaving,
                              decoration: InputDecoration(
                                labelText: 'Registration Number',
                                prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: rollCtrl,
                              enabled: !isSaving,
                              decoration: InputDecoration(
                                labelText: 'Roll Number',
                                prefixIcon: const Icon(Icons.numbers_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: admissionYearCtrl,
                            enabled: !isSaving,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Admission Year',
                              hintText: 'e.g. 2024',
                              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ] else if (role == 'FACULTY') ...[
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedDeptId,
                            decoration: InputDecoration(
                              labelText: 'Faculty Department *',
                              prefixIcon: const Icon(Icons.business_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                            items: [
                              ...depts.map((d) => DropdownMenuItem(
                                    value: d['id'].toString(),
                                    child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: isSaving ? null : (val) => setDialogState(() => selectedDeptId = val),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: designationCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'Designation / Title',
                              hintText: 'e.g. Assistant Professor',
                              prefixIcon: const Icon(Icons.school_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: officeRoomCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'Office Room / Cabin',
                              hintText: 'e.g. CSE Block Room 204',
                              prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Faculty Credentials',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Set a temporary password forcing password change on login',
                                        style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showSetTemporaryPasswordDialog(
                                      context,
                                      userId,
                                      '${firstNameCtrl.text} ${lastNameCtrl.text}'.trim(),
                                      emailCtrl.text.trim(),
                                    );
                                  },
                                  icon: const Icon(Icons.key_rounded, size: 15),
                                  label: const Text('Set Temp Pass', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (role == 'PLACEMENT') ...[
                          TextField(
                            controller: designationCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'Placement Designation',
                              hintText: 'e.g. Placement Officer',
                              prefixIcon: const Icon(Icons.work_outline, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: officeRoomCtrl,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              labelText: 'Office Room / Cabin',
                              hintText: 'e.g. Placement Cell Main Office',
                              prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Placement Credentials',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Set a temporary password forcing password change on login',
                                        style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showSetTemporaryPasswordDialog(
                                      context,
                                      userId,
                                      '${firstNameCtrl.text} ${lastNameCtrl.text}'.trim(),
                                      emailCtrl.text.trim(),
                                    );
                                  },
                                  icon: const Icon(Icons.key_rounded, size: 15),
                                  label: const Text('Set Temp Pass', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (role == 'DEPT_ADMIN') ...[
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedDeptId,
                            decoration: InputDecoration(
                              labelText: 'Department Administration Scope *',
                              prefixIcon: const Icon(Icons.business_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                            items: [
                              ...depts.map((d) => DropdownMenuItem(
                                    value: d['id'].toString(),
                                    child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: isSaving ? null : (val) => setDialogState(() => selectedDeptId = val),
                          ),
                        ] else if (role == 'ADMIN') ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 22),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Chief Institutional Administrator: Account has institution-wide scope across all departments.',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final firstName = firstNameCtrl.text.trim();
                        final lastName = lastNameCtrl.text.trim();

                        if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid email address')),
                          );
                          return;
                        }
                        if (firstName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('First name is required')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final payload = <String, dynamic>{
                            'firstName': firstName,
                            'lastName': lastName,
                            'email': email,
                            'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                            'status': selectedStatus,
                          };

                          if (role == 'STUDENT') {
                            payload['rollNumber'] = rollCtrl.text.trim().isNotEmpty ? rollCtrl.text.trim() : null;
                            payload['registrationNumber'] = regNoCtrl.text.trim().isNotEmpty ? regNoCtrl.text.trim() : null;
                            payload['departmentId'] = selectedDeptId;
                            payload['batchName'] = selectedBatch;
                            payload['year'] = selectedYear;
                            int cyNum = 1;
                            if (selectedYear == '2nd Year') {
                              cyNum = 2;
                            } else if (selectedYear == '3rd Year') {
                              cyNum = 3;
                            } else if (selectedYear == '4th Year') {
                              cyNum = 4;
                            } else if (selectedYear == 'Graduated') {
                              cyNum = 5;
                            }
                            payload['currentYear'] = cyNum;

                            final match = RegExp(r'^(\d{4})').firstMatch(selectedBatch);
                            if (match != null) {
                              payload['admissionYear'] = int.parse(match.group(1)!);
                            } else {
                              final admYear = int.tryParse(admissionYearCtrl.text.trim());
                              if (admYear != null) payload['admissionYear'] = admYear;
                            }
                          } else if (role == 'FACULTY') {
                            payload['departmentId'] = selectedDeptId;
                            payload['designation'] = designationCtrl.text.trim().isNotEmpty ? designationCtrl.text.trim() : null;
                            payload['officeRoom'] = officeRoomCtrl.text.trim().isNotEmpty ? officeRoomCtrl.text.trim() : null;
                          } else if (role == 'PLACEMENT') {
                            payload['designation'] = designationCtrl.text.trim().isNotEmpty ? designationCtrl.text.trim() : null;
                            payload['officeRoom'] = officeRoomCtrl.text.trim().isNotEmpty ? officeRoomCtrl.text.trim() : null;
                          } else if (role == 'DEPT_ADMIN') {
                            payload['departmentId'] = selectedDeptId;
                          } else if (role == 'ADMIN') {
                            payload['departmentId'] = null;
                          }

                          await ref.read(adminRemoteDataSourceProvider).updateUser(userId, payload);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) setState(() {});
                          ref.invalidate(adminUsersProvider);
                          ref.invalidate(adminAuditReportsProvider);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('User profile updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to update user: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSetTemporaryPasswordDialog(BuildContext context, String userId, String userName, String userEmail) {
    final tempPassCtrl = TextEditingController(
      text: 'Gcee@${DateTime.now().year}${Random().nextInt(900) + 100}',
    );
    bool obscure = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final theme = Theme.of(context);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.key_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Set Temporary Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Assigning a temporary password will reset existing logins and require $userName ($userEmail) to configure a new password on their next sign-in.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextField(
                    controller: tempPassCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Temporary Password',
                      hintText: 'Enter temporary password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscure = !obscure),
                          ),
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            tooltip: 'Generate Random Password',
                            onPressed: () {
                              setDialogState(() {
                                tempPassCtrl.text = 'Gcee@${DateTime.now().year}${Random().nextInt(900) + 100}';
                              });
                            },
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm & Set Password'),
                onPressed: () async {
                  final password = tempPassCtrl.text.trim();
                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters long'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final res = await ref.read(adminRemoteDataSourceProvider).setTemporaryPassword(
                          userId,
                          tempPassword: password,
                        );
                    ref.invalidate(adminUsersProvider);
                    ref.invalidate(adminAuditReportsProvider);

                    final setPassword = res['tempPassword']?.toString() ?? password;

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (successCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success),
                              const SizedBox(width: 10),
                              const Text('Temporary Password Set'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A temporary password was set for $userName ($userEmail):',
                                style: const TextStyle(fontSize: 13.5),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: SelectableText(
                                  setPassword,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Share this temporary password securely with the user.',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: setPassword));
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Temporary password copied to clipboard!')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copy Password'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(successCtx),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to set temporary password: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final name = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'User';
    final email = user['email'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_delete_outlined, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Move User to Recycle Bin',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to move '$name' ($email) to the Recycle Bin?\n\nThe user's access will be revoked and the account will remain in the Recycle Bin for 30 days before being permanently purged. You can restore this user anytime during this period.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(adminRemoteDataSourceProvider).deleteUser(userId);
                if (mounted) setState(() {});
                ref.invalidate(adminUsersProvider);
                ref.invalidate(adminBinUsersProvider);
                ref.invalidate(adminMetricsProvider);
                ref.invalidate(adminAuditReportsProvider);
                messenger.showSnackBar(
                  SnackBar(content: Text("User '$name' moved to Recycle Bin")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Move to Bin'),
          ),
        ],
      ),
    );
  }

  void _showRecycleBinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final binAsync = ref.watch(adminBinUsersProvider(null));
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = (screenWidth * 0.92).clamp(320.0, 680.0);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 24, 16),
            title: Row(
              children: [
                Icon(Icons.auto_delete_outlined, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recycle Bin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Deleted accounts are retained for 30 days before purge',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              height: MediaQuery.of(context).size.height * 0.65,
              child: binAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Recycle Bin is empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('No deleted accounts pending purge or restoration', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${users.length} accounts in bin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_forever_outlined, size: 16, color: Colors.red),
                            label: const Text('Purge Expired (> 30 Days)', style: TextStyle(fontSize: 12, color: Colors.red)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final res = await ref.read(adminRemoteDataSourceProvider).purgeBin();
                                ref.invalidate(adminBinUsersProvider(null));
                                ref.invalidate(adminMetricsProvider);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Purged ${res['count'] ?? 0} expired accounts')),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to purge: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = users[index] as Map<String, dynamic>;
                            final uid = u['id']?.toString() ?? '';
                            final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
                            final email = u['email'] ?? '';
                            final role = u['role'] ?? 'STUDENT';
                            final daysLeft = u['days_left'] ?? 30;
                            final deptName = u['department']?['code'] ?? u['department']?['name'] ?? 'No Dept';

                            return CampusGlassPanel(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name.isNotEmpty ? name : 'User',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(role).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                role,
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getRoleColor(role)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (daysLeft <= 5 ? Colors.red : Colors.orange).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.timer_outlined, size: 11, color: daysLeft <= 5 ? Colors.red : Colors.orange.shade800),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$daysLeft days left',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: daysLeft <= 5 ? Colors.red : Colors.orange.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              deptName,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash_outlined, color: Colors.green, size: 22),
                                    tooltip: 'Restore User',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await ref.read(adminRemoteDataSourceProvider).restoreUser(uid);
                                        ref.invalidate(adminBinUsersProvider(null));
                                        ref.invalidate(adminUsersProvider);
                                        ref.invalidate(adminMetricsProvider);
                                        messenger.showSnackBar(
                                          SnackBar(content: Text("Restored '$name' successfully")),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Failed to restore: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, color: Colors.red.shade600, size: 22),
                                    tooltip: 'Delete Permanently',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Permanent Deletion'),
                                          content: Text("Permanently delete '$name' ($email)? This action cannot be undone."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('Delete Forever'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        if (!context.mounted) return;
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await ref.read(adminRemoteDataSourceProvider).permanentlyDeleteUser(uid);
                                          ref.invalidate(adminBinUsersProvider(null));
                                          messenger.showSnackBar(
                                            SnackBar(content: Text("Permanently deleted '$name'")),
                                          );
                                        } catch (e) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Failed to delete permanently: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading bin: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddAcademicYearDialog(BuildContext context) {
    final yearNameCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '${DateTime.now().year}-08-01');
    final endCtrl = TextEditingController(text: '${DateTime.now().year + 1}-05-31');
    bool isActive = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Add Academic Year'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: yearNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Year Name (e.g. 2026-2027) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'End Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as Current Active Year'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final yName = yearNameCtrl.text.trim();
                final sDate = startCtrl.text.trim();
                final eDate = endCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);

                if (yName.isEmpty || sDate.isEmpty || eDate.isEmpty) {
                  messenger.showSnackBar(const SnackBar(content: Text('All fields are required')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRemoteDataSourceProvider).createAcademicYear({
                    'yearName': yName,
                    'startDate': sDate,
                    'endDate': eDate,
                    'isActive': isActive,
                  });
                  ref.invalidate(adminAcademicYearsProvider);
                  ref.invalidate(adminAuditReportsProvider);
                  messenger.showSnackBar(SnackBar(content: Text("Academic year '$yName' created successfully")));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Create Year'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAcademicYearDialog(BuildContext context, Map<String, dynamic> year) {
    final yearId = year['id']?.toString() ?? '';
    final yearNameCtrl = TextEditingController(text: year['year_name']?.toString() ?? '');
    final startCtrl = TextEditingController(
      text: year['start_date']?.toString().split('T').first ?? '',
    );
    final endCtrl = TextEditingController(
      text: year['end_date']?.toString().split('T').first ?? '',
    );
    bool isActive = year['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Academic Year'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: yearNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Year Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'End Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as Current Active Year'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final yName = yearNameCtrl.text.trim();
                final sDate = startCtrl.text.trim();
                final eDate = endCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);

                if (yName.isEmpty || sDate.isEmpty || eDate.isEmpty) {
                  messenger.showSnackBar(const SnackBar(content: Text('All fields are required')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRemoteDataSourceProvider).updateAcademicYear(yearId, {
                    'yearName': yName,
                    'startDate': sDate,
                    'endDate': eDate,
                    'isActive': isActive,
                  });
                  ref.invalidate(adminAcademicYearsProvider);
                  ref.invalidate(adminAuditReportsProvider);
                  messenger.showSnackBar(SnackBar(content: Text("Academic year '$yName' updated successfully")));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTermDialog(BuildContext context, String yearId, String yearName) {
    final nameCtrl = TextEditingController();
    final semCtrl = TextEditingController(text: '1');
    final startCtrl = TextEditingController(text: '${DateTime.now().year}-08-01');
    final endCtrl = TextEditingController(text: '${DateTime.now().year}-12-20');
    String termType = 'ODD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Add Term to $yearName'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Term Name (e.g. Fall Semester 1) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: termType,
                    decoration: const InputDecoration(
                      labelText: 'Term Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ODD', child: Text('Odd Semester')),
                      DropdownMenuItem(value: 'EVEN', child: Text('Even Semester')),
                      DropdownMenuItem(value: 'SUMMER', child: Text('Summer Term')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => termType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: semCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Semester Number (1-10) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'End Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final sem = int.tryParse(semCtrl.text.trim());
                final messenger = ScaffoldMessenger.of(context);

                if (name.isEmpty || sem == null) {
                  messenger.showSnackBar(const SnackBar(content: Text('Name and valid semester number are required')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRemoteDataSourceProvider).createAcademicTerm({
                    'academicYearId': yearId,
                    'name': name,
                    'termType': termType,
                    'semesterNumber': sem,
                    'startDate': startCtrl.text.trim(),
                    'endDate': endCtrl.text.trim(),
                  });
                  ref.invalidate(adminAcademicTermsProvider(yearId));
                  ref.invalidate(adminAcademicYearsProvider);
                  ref.invalidate(adminAuditReportsProvider);
                  messenger.showSnackBar(SnackBar(content: Text("Term '$name' created successfully")));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Create Term'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTermDialog(BuildContext context, String yearId, Map<String, dynamic> term) {
    final termId = term['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: term['name']?.toString() ?? '');
    final semCtrl = TextEditingController(text: '${term['semester_number'] ?? 1}');
    final startCtrl = TextEditingController(
      text: term['start_date']?.toString().split('T').first ?? '',
    );
    final endCtrl = TextEditingController(
      text: term['end_date']?.toString().split('T').first ?? '',
    );
    String termType = term['term_type']?.toString().toUpperCase() ?? 'ODD';
    if (!['ODD', 'EVEN', 'SUMMER'].contains(termType)) termType = 'ODD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Academic Term'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Term Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: termType,
                    decoration: const InputDecoration(
                      labelText: 'Term Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ODD', child: Text('Odd Semester')),
                      DropdownMenuItem(value: 'EVEN', child: Text('Even Semester')),
                      DropdownMenuItem(value: 'SUMMER', child: Text('Summer Term')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => termType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: semCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Semester Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'End Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final sem = int.tryParse(semCtrl.text.trim());
                final messenger = ScaffoldMessenger.of(context);

                if (name.isEmpty || sem == null) {
                  messenger.showSnackBar(const SnackBar(content: Text('Name and valid semester number are required')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRemoteDataSourceProvider).updateAcademicTerm(termId, {
                    'name': name,
                    'termType': termType,
                    'semesterNumber': sem,
                    'startDate': startCtrl.text.trim(),
                    'endDate': endCtrl.text.trim(),
                  });
                  ref.invalidate(adminAcademicTermsProvider(yearId));
                  ref.invalidate(adminAcademicYearsProvider);
                  ref.invalidate(adminAuditReportsProvider);
                  messenger.showSnackBar(SnackBar(content: Text("Term '$name' updated successfully")));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProgramDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final semCtrl = TextEditingController(text: '8');
    String degreeType = 'UNDERGRADUATE';
    String? selectedDeptId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];

          return AlertDialog(
            title: const Text('Add Academic Degree Program'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Program Name (e.g. B.Tech Computer Science) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Program Code (e.g. BTECH-CSE) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                      items: depts
                          .map((d) => DropdownMenuItem(
                                value: d['id'].toString(),
                                child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: degreeType,
                      decoration: const InputDecoration(
                        labelText: 'Degree Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'UNDERGRADUATE', child: Text('Undergraduate (Bachelor)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'POSTGRADUATE', child: Text('Postgraduate (Master)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'DIPLOMA', child: Text('Diploma', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'DOCTORAL', child: Text('Doctoral (PhD)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => degreeType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: semCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Semesters (e.g. 8) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim().toUpperCase();
                  final sem = int.tryParse(semCtrl.text.trim()) ?? 8;
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || code.isEmpty || selectedDeptId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name, code, and department are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createAcademicProgram({
                      'departmentId': selectedDeptId,
                      'name': name,
                      'code': code,
                      'degreeType': degreeType,
                      'totalSemesters': sem,
                    });
                    ref.invalidate(adminProgramsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Program '$name' created successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Create Program'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProgramDialog(BuildContext context, Map<String, dynamic> program) {
    final progId = program['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: program['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: program['code']?.toString() ?? '');
    final semCtrl = TextEditingController(text: '${program['total_semesters'] ?? 8}');
    String degreeType = program['degree_type']?.toString().toUpperCase() ?? 'UNDERGRADUATE';
    if (!['UNDERGRADUATE', 'POSTGRADUATE', 'DIPLOMA', 'DOCTORAL'].contains(degreeType)) {
      degreeType = 'UNDERGRADUATE';
    }
    String? selectedDeptId = program['department_id']?.toString() ?? program['department']?['id']?.toString();
    bool isActive = program['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];

          return AlertDialog(
            title: const Text('Edit Academic Degree Program'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Program Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Program Code *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department', overflow: TextOverflow.ellipsis),
                      items: depts
                          .map((d) => DropdownMenuItem(
                                value: d['id'].toString(),
                                child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: degreeType,
                      decoration: const InputDecoration(
                        labelText: 'Degree Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'UNDERGRADUATE', child: Text('Undergraduate (Bachelor)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'POSTGRADUATE', child: Text('Postgraduate (Master)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'DIPLOMA', child: Text('Diploma', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'DOCTORAL', child: Text('Doctoral (PhD)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => degreeType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: semCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Semesters *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active Status'),
                      subtitle: Text(isActive ? 'Program is currently active' : 'Program is inactive'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim().toUpperCase();
                  final sem = int.tryParse(semCtrl.text.trim()) ?? 8;
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || code.isEmpty) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name and code are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateAcademicProgram(progId, {
                      if (selectedDeptId != null) 'departmentId': selectedDeptId,
                      'name': name,
                      'code': code,
                      'degreeType': degreeType,
                      'totalSemesters': sem,
                      'isActive': isActive,
                    });
                    ref.invalidate(adminProgramsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Program '$name' updated successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final admYearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final gradYearCtrl = TextEditingController(text: '${DateTime.now().year + 4}');
    String? selectedProgramId;
    String? selectedDeptId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final progs = ref.watch(adminProgramsProvider(null)).value ?? [];
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];

          return AlertDialog(
            title: const Text('Add Student Cohort Batch'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch Name (e.g. Batch 2026) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedProgramId,
                      decoration: const InputDecoration(
                        labelText: 'Program (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Program'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...progs.map((p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text('${p['code']} - ${p['name']}', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProgramId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...depts.map((d) => DropdownMenuItem(
                              value: d['id'].toString(),
                              child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: admYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Admission Year (e.g. 2026) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: gradYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Graduation Year (e.g. 2030) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final adm = int.tryParse(admYearCtrl.text.trim());
                  final grad = int.tryParse(gradYearCtrl.text.trim());
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || adm == null || grad == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name and valid admission/graduation years are required')));
                    return;
                  }
                  if (adm > grad) {
                    messenger.showSnackBar(const SnackBar(content: Text('Admission year must precede graduation year')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createBatch({
                      'name': name,
                      'admissionYear': adm,
                      'graduationYear': grad,
                      if (selectedProgramId != null) 'programId': selectedProgramId,
                      if (selectedDeptId != null) 'departmentId': selectedDeptId,
                    });
                    ref.invalidate(adminBatchesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Batch '$name' created successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Create Batch'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditBatchDialog(BuildContext context, Map<String, dynamic> batch) {
    final batchId = batch['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: batch['name']?.toString() ?? '');
    final admYearCtrl = TextEditingController(text: '${batch['admission_year'] ?? DateTime.now().year}');
    final gradYearCtrl = TextEditingController(text: '${batch['graduation_year'] ?? DateTime.now().year + 4}');
    String? selectedProgramId = batch['program_id']?.toString() ?? batch['program']?['id']?.toString();
    String? selectedDeptId = batch['department_id']?.toString() ?? batch['department']?['id']?.toString();
    String status = batch['status']?.toString().toUpperCase() ?? 'ACTIVE';
    if (!['ACTIVE', 'COMPLETED', 'ARCHIVED'].contains(status)) status = 'ACTIVE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final progs = ref.watch(adminProgramsProvider(null)).value ?? [];
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];

          return AlertDialog(
            title: const Text('Edit Student Cohort Batch'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedProgramId,
                      decoration: const InputDecoration(
                        labelText: 'Program (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Program'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...progs.map((p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text('${p['code']} - ${p['name']}', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProgramId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...depts.map((d) => DropdownMenuItem(
                              value: d['id'].toString(),
                              child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: admYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Admission Year *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: gradYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Graduation Year *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                        DropdownMenuItem(value: 'ARCHIVED', child: Text('ARCHIVED')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final adm = int.tryParse(admYearCtrl.text.trim());
                  final grad = int.tryParse(gradYearCtrl.text.trim());
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || adm == null || grad == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name and valid admission/graduation years are required')));
                    return;
                  }
                  if (adm > grad) {
                    messenger.showSnackBar(const SnackBar(content: Text('Admission year must precede graduation year')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateBatch(batchId, {
                      'name': name,
                      'admissionYear': adm,
                      'graduationYear': grad,
                      'status': status,
                      if (selectedProgramId != null) 'programId': selectedProgramId,
                      if (selectedDeptId != null) 'departmentId': selectedDeptId,
                    });
                    ref.invalidate(adminBatchesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Batch '$name' updated successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'A');
    final semCtrl = TextEditingController(text: '1');
    final creditsCtrl = TextEditingController(text: '3');
    String? selectedDeptId;
    String? selectedFacultyId;
    String? selectedTermId;
    String selectedType = 'THEORY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];
          final terms = ref.watch(adminAcademicTermsProvider(null)).value ?? [];

          return AlertDialog(
            title: const Text('Add Course / Subject'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name (e.g. Operating Systems) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course Code (e.g. CS201) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: depts.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedFacultyId,
                      decoration: const InputDecoration(
                        labelText: 'Lead Instructor (Faculty) *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Faculty'),
                      items: faculties.map((f) => DropdownMenuItem(
                        value: f['id'].toString(),
                        child: Text('${f['first_name']} ${f['last_name']} (${f['email']})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedFacultyId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedTermId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Term (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Term'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...terms.map((t) => DropdownMenuItem(
                          value: t['id'].toString(),
                          child: Text('${t['name']} (${t['semester_type']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedTermId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: semCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Semester (1-8) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sectionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Section (e.g. A) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: creditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Credits (e.g. 3) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Course Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'THEORY', child: Text('Theory', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'LAB', child: Text('Lab', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'ELECTIVE', child: Text('Elective', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'PROJECT', child: Text('Project', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final section = sectionCtrl.text.trim().toUpperCase();
                  final sem = int.tryParse(semCtrl.text.trim());
                  final creds = int.tryParse(creditsCtrl.text.trim());
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || code.isEmpty || section.isEmpty || sem == null || creds == null || selectedDeptId == null || selectedFacultyId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('All required fields marked with * must be filled')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createSubject({
                      'name': name,
                      'code': code,
                      'section': section,
                      'semester': sem,
                      'credits': creds,
                      'type': selectedType,
                      'departmentId': selectedDeptId,
                      'facultyId': selectedFacultyId,
                      if (selectedTermId != null) 'academicTermId': selectedTermId,
                    });
                    ref.invalidate(adminSubjectsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Course '$code - $name' created successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Create Subject'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Map<String, dynamic> subject) {
    final subjectId = subject['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: subject['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: subject['code']?.toString() ?? '');
    final sectionCtrl = TextEditingController(text: subject['section']?.toString() ?? 'A');
    final semCtrl = TextEditingController(text: '${subject['semester'] ?? 1}');
    final creditsCtrl = TextEditingController(text: '${subject['credits'] ?? 3}');
    String? selectedDeptId = subject['department_id']?.toString() ?? subject['department']?['id']?.toString();
    String? selectedFacultyId = subject['faculty_id']?.toString() ?? subject['faculty']?['id']?.toString();
    String? selectedTermId = subject['academic_term_id']?.toString() ?? subject['academic_term']?['id']?.toString();
    String selectedType = subject['type']?.toString().toUpperCase() ?? 'THEORY';
    if (!['THEORY', 'LAB', 'ELECTIVE', 'PROJECT'].contains(selectedType)) {
      selectedType = 'THEORY';
    }
    String status = subject['status']?.toString().toUpperCase() ?? 'ACTIVE';
    if (!['ACTIVE', 'INACTIVE'].contains(status)) status = 'ACTIVE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];
          final terms = ref.watch(adminAcademicTermsProvider(null)).value ?? [];

          return AlertDialog(
            title: const Text('Edit Course / Subject'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course Code *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: depts.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedFacultyId,
                      decoration: const InputDecoration(
                        labelText: 'Lead Instructor (Faculty) *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Faculty'),
                      items: faculties.map((f) => DropdownMenuItem(
                        value: f['id'].toString(),
                        child: Text('${f['first_name']} ${f['last_name']} (${f['email']})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedFacultyId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedTermId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Term (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Term'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...terms.map((t) => DropdownMenuItem(
                          value: t['id'].toString(),
                          child: Text('${t['name']} (${t['semester_type']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedTermId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: semCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Semester (1-8) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sectionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Section *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: creditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Credits *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Course Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'THEORY', child: Text('Theory', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'LAB', child: Text('Lab', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'ELECTIVE', child: Text('Elective', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'PROJECT', child: Text('Project', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final section = sectionCtrl.text.trim().toUpperCase();
                  final sem = int.tryParse(semCtrl.text.trim());
                  final creds = int.tryParse(creditsCtrl.text.trim());
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || code.isEmpty || section.isEmpty || sem == null || creds == null || selectedDeptId == null || selectedFacultyId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('All required fields marked with * must be filled')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateSubject(subjectId, {
                      'name': name,
                      'code': code,
                      'section': section,
                      'semester': sem.toString(),
                      'credits': creds,
                      'subjectType': selectedType,
                      'departmentId': selectedDeptId,
                      'facultyId': selectedFacultyId,
                      'status': status,
                      if (selectedTermId != null) 'academicTermId': selectedTermId,
                    });
                    ref.invalidate(adminSubjectsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Course '$code - $name' updated successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'A');
    final yearCtrl = TextEditingController(text: '1');
    final semCtrl = TextEditingController(text: '1');
    final capacityCtrl = TextEditingController(text: '60');
    String? selectedDeptId;
    String? selectedProgId;
    String? selectedAdvisorId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final progs = ref.watch(adminProgramsProvider(null)).value ?? [];
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];

          return AlertDialog(
            title: const Text('Add Academic Class / Section'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Class Name (e.g. B.Tech CSE 2026 - A) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: depts.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedProgId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Program (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Program'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...progs.map((p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text('${p['code']} - ${p['name']}', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProgId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAdvisorId,
                      decoration: const InputDecoration(
                        labelText: 'Class Advisor (Faculty)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Class Advisor'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / Unassigned', overflow: TextOverflow.ellipsis)),
                        ...faculties.map((f) => DropdownMenuItem(
                          value: f['id'].toString(),
                          child: Text('${f['first_name']} ${f['last_name']} (${f['email']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedAdvisorId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Year of Study (1-4) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: semCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Semester (1-8) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sectionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Section (e.g. A) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity (Default 60) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final section = sectionCtrl.text.trim().toUpperCase();
                  final year = int.tryParse(yearCtrl.text.trim());
                  final sem = int.tryParse(semCtrl.text.trim());
                  final cap = int.tryParse(capacityCtrl.text.trim()) ?? 60;
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || section.isEmpty || year == null || sem == null || selectedDeptId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name, section, year, semester, and department are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createAcademicClass({
                      'name': name,
                      'section': section,
                      'yearOfStudy': year,
                      'semester': sem,
                      'capacity': cap,
                      'departmentId': selectedDeptId,
                      if (selectedProgId != null) 'programId': selectedProgId,
                      if (selectedAdvisorId != null) 'classAdvisorId': selectedAdvisorId,
                    });
                    ref.invalidate(adminClassesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Academic class '$name' created successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Create Class'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, Map<String, dynamic> cls) {
    final classId = cls['id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: cls['name']?.toString() ?? '');
    final sectionCtrl = TextEditingController(text: cls['section']?.toString() ?? 'A');
    final yearCtrl = TextEditingController(text: '${cls['year_of_study'] ?? 1}');
    final semCtrl = TextEditingController(text: '${cls['semester'] ?? 1}');
    final capacityCtrl = TextEditingController(text: '${cls['capacity'] ?? 60}');
    String? selectedDeptId = cls['department_id']?.toString() ?? cls['department']?['id']?.toString();
    String? selectedProgId = cls['program_id']?.toString() ?? cls['program']?['id']?.toString();
    String? selectedAdvisorId = cls['class_advisor_id']?.toString() ?? cls['class_advisor']?['id']?.toString();
    bool isActive = cls['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];
          final progs = ref.watch(adminProgramsProvider(null)).value ?? [];
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];

          return AlertDialog(
            title: const Text('Edit Academic Class / Section'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Class Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Department'),
                      items: depts.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text('${d['code']} - ${d['name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedProgId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Program (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Program'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General', overflow: TextOverflow.ellipsis)),
                        ...progs.map((p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text('${p['code']} - ${p['name']}', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProgId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAdvisorId,
                      decoration: const InputDecoration(
                        labelText: 'Class Advisor (Faculty)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Class Advisor'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / Unassigned', overflow: TextOverflow.ellipsis)),
                        ...faculties.map((f) => DropdownMenuItem(
                          value: f['id'].toString(),
                          child: Text('${f['first_name']} ${f['last_name']} (${f['email']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedAdvisorId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Year of Study (1-4) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: semCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Semester (1-8) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sectionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Section *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active Status'),
                      subtitle: Text(isActive ? 'Class is currently active' : 'Class is inactive'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final section = sectionCtrl.text.trim().toUpperCase();
                  final year = int.tryParse(yearCtrl.text.trim());
                  final sem = int.tryParse(semCtrl.text.trim());
                  final cap = int.tryParse(capacityCtrl.text.trim()) ?? 60;
                  final messenger = ScaffoldMessenger.of(context);

                  if (name.isEmpty || section.isEmpty || year == null || sem == null || selectedDeptId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Name, section, year, semester, and department are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateAcademicClass(classId, {
                      'name': name,
                      'section': section,
                      'yearOfStudy': year,
                      'semester': sem,
                      'capacity': cap,
                      'departmentId': selectedDeptId,
                      'programId': selectedProgId,
                      'classAdvisorId': selectedAdvisorId,
                    });
                    ref.invalidate(adminClassesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Academic class '$name' updated successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: '1');
    final capCtrl = TextEditingController(text: '60');
    String selectedRoomType = 'LECTURE_HALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Campus Room / Venue'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Code (e.g. LH-101, LAB-2) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Name (e.g. Newton Hall) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: buildingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Building / Block (e.g. Science Block)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: floorCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Floor (e.g. 1) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity (e.g. 60) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRoomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'LECTURE_HALL', child: Text('Lecture Hall')),
                        DropdownMenuItem(value: 'LAB', child: Text('Laboratory')),
                        DropdownMenuItem(value: 'SEMINAR_HALL', child: Text('Seminar Hall')),
                        DropdownMenuItem(value: 'AUDITORIUM', child: Text('Auditorium')),
                        DropdownMenuItem(value: 'CLASSROOM', child: Text('Classroom')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRoomType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final code = codeCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final bld = buildingCtrl.text.trim();
                  final floor = int.tryParse(floorCtrl.text.trim()) ?? 1;
                  final cap = int.tryParse(capCtrl.text.trim()) ?? 60;
                  final messenger = ScaffoldMessenger.of(context);

                  if (code.isEmpty || name.isEmpty) {
                    messenger.showSnackBar(const SnackBar(content: Text('Room code and name are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createRoom({
                      'code': code,
                      'name': name,
                      if (bld.isNotEmpty) 'building': bld,
                      'floor': floor,
                      'capacity': cap,
                      'roomType': selectedRoomType,
                    });
                    ref.invalidate(adminRoomsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Room '$code - $name' created successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Create Room'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRoomDialog(BuildContext context, Map<String, dynamic> room) {
    final roomId = room['id']?.toString() ?? '';
    final codeCtrl = TextEditingController(text: room['code']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: room['name']?.toString() ?? '');
    final buildingCtrl = TextEditingController(text: room['building']?.toString() ?? '');
    final floorCtrl = TextEditingController(text: '${room['floor'] ?? 1}');
    final capCtrl = TextEditingController(text: '${room['capacity'] ?? 60}');
    String selectedRoomType = room['room_type']?.toString().toUpperCase() ?? 'LECTURE_HALL';
    if (!['LECTURE_HALL', 'LAB', 'SEMINAR_HALL', 'AUDITORIUM', 'CLASSROOM'].contains(selectedRoomType)) {
      selectedRoomType = 'LECTURE_HALL';
    }
    bool isActive = room['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Campus Room / Venue'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Code *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: buildingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Building / Block',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: floorCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Floor *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRoomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'LECTURE_HALL', child: Text('Lecture Hall')),
                        DropdownMenuItem(value: 'LAB', child: Text('Laboratory')),
                        DropdownMenuItem(value: 'SEMINAR_HALL', child: Text('Seminar Hall')),
                        DropdownMenuItem(value: 'AUDITORIUM', child: Text('Auditorium')),
                        DropdownMenuItem(value: 'CLASSROOM', child: Text('Classroom')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRoomType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active / Available'),
                      subtitle: Text(isActive ? 'Room is available for classes' : 'Room is under maintenance/inactive'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final code = codeCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final bld = buildingCtrl.text.trim();
                  final floor = int.tryParse(floorCtrl.text.trim()) ?? 1;
                  final cap = int.tryParse(capCtrl.text.trim()) ?? 60;
                  final messenger = ScaffoldMessenger.of(context);

                  if (code.isEmpty || name.isEmpty) {
                    messenger.showSnackBar(const SnackBar(content: Text('Room code and name are required')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateRoom(roomId, {
                      'code': code,
                      'name': name,
                      if (bld.isNotEmpty) 'building': bld,
                      'floor': floor,
                      'capacity': cap,
                      'roomType': selectedRoomType,
                      'isActive': isActive,
                    });
                    ref.invalidate(adminRoomsProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(SnackBar(content: Text("Room '$code - $name' updated successfully")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '10:00');
    String selectedDay = 'MONDAY';
    String? selectedFacultyId;
    String? selectedSubjectId;
    String? selectedClassId;
    String? selectedRoomId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];
          final subjects = ref.watch(adminSubjectsProvider(null)).value ?? [];
          final classes = ref.watch(adminClassesProvider(null)).value ?? [];
          final rooms = ref.watch(adminRoomsProvider(null)).value ?? [];

          return AlertDialog(
            title: const Text('Add Timetable Slot'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MONDAY', child: Text('Monday')),
                        DropdownMenuItem(value: 'TUESDAY', child: Text('Tuesday')),
                        DropdownMenuItem(value: 'WEDNESDAY', child: Text('Wednesday')),
                        DropdownMenuItem(value: 'THURSDAY', child: Text('Thursday')),
                        DropdownMenuItem(value: 'FRIDAY', child: Text('Friday')),
                        DropdownMenuItem(value: 'SATURDAY', child: Text('Saturday')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Start (HH:mm) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            decoration: const InputDecoration(
                              labelText: 'End (HH:mm) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedFacultyId,
                      decoration: const InputDecoration(
                        labelText: 'Faculty Member *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Faculty'),
                      items: faculties.map((f) => DropdownMenuItem(
                        value: f['id'].toString(),
                        child: Text('${f['first_name']} ${f['last_name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedFacultyId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Course (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Subject'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General Session', overflow: TextOverflow.ellipsis)),
                        ...subjects.map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text('${s['code']} - ${s['name']}', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Class (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Class'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / All Classes', overflow: TextOverflow.ellipsis)),
                        ...classes.map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text('${c['name']} (${c['section']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedClassId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: 'Room / Venue (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Room'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / Virtual', overflow: TextOverflow.ellipsis)),
                        ...rooms.map((r) => DropdownMenuItem(
                          value: r['id'].toString(),
                          child: Text('${r['code']} (${r['name']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedRoomId = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final start = startCtrl.text.trim();
                  final end = endCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);

                  if (start.isEmpty || end.isEmpty || selectedFacultyId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Faculty, start time, and end time are required')));
                    return;
                  }
                  if (start.compareTo(end) >= 0) {
                    messenger.showSnackBar(const SnackBar(content: Text('Start time must precede end time')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).createSchedule({
                      'facultyId': selectedFacultyId,
                      'dayOfWeek': selectedDay,
                      'startTime': start,
                      'endTime': end,
                      if (selectedSubjectId != null) 'subjectId': selectedSubjectId,
                      if (selectedClassId != null) 'classId': selectedClassId,
                      if (selectedRoomId != null) 'roomId': selectedRoomId,
                    });
                    ref.invalidate(adminSchedulesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(const SnackBar(content: Text('Timetable slot created successfully')));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Schedule Conflict / Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ));
                  }
                },
                child: const Text('Create Slot'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, Map<String, dynamic> schedule) {
    final scheduleId = schedule['id']?.toString() ?? '';
    final startCtrl = TextEditingController(text: schedule['start_time']?.toString() ?? '09:00');
    final endCtrl = TextEditingController(text: schedule['end_time']?.toString() ?? '10:00');
    String selectedDay = schedule['day_of_week']?.toString().toUpperCase() ?? 'MONDAY';
    if (!['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'].contains(selectedDay)) {
      selectedDay = 'MONDAY';
    }
    String? selectedFacultyId = schedule['faculty_id']?.toString() ?? schedule['faculty']?['id']?.toString();
    String? selectedSubjectId = schedule['subject_id']?.toString() ?? schedule['subject']?['id']?.toString();
    String? selectedClassId = schedule['class_id']?.toString() ?? schedule['class']?['id']?.toString();
    String? selectedRoomId = schedule['room_id']?.toString() ?? schedule['room']?['id']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final faculties = ref.watch(adminUsersProvider(const AdminUsersFilter(role: 'FACULTY'))).value ?? [];
          final subjects = ref.watch(adminSubjectsProvider(null)).value ?? [];
          final classes = ref.watch(adminClassesProvider(null)).value ?? [];
          final rooms = ref.watch(adminRoomsProvider(null)).value ?? [];

          return AlertDialog(
            title: const Text('Edit Timetable Slot'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MONDAY', child: Text('Monday')),
                        DropdownMenuItem(value: 'TUESDAY', child: Text('Tuesday')),
                        DropdownMenuItem(value: 'WEDNESDAY', child: Text('Wednesday')),
                        DropdownMenuItem(value: 'THURSDAY', child: Text('Thursday')),
                        DropdownMenuItem(value: 'FRIDAY', child: Text('Friday')),
                        DropdownMenuItem(value: 'SATURDAY', child: Text('Saturday')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Start (HH:mm) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            decoration: const InputDecoration(
                              labelText: 'End (HH:mm) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedFacultyId,
                      decoration: const InputDecoration(
                        labelText: 'Faculty Member *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Faculty'),
                      items: faculties.map((f) => DropdownMenuItem(
                        value: f['id'].toString(),
                        child: Text('${f['first_name']} ${f['last_name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedFacultyId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Course (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Subject'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / General Session', overflow: TextOverflow.ellipsis)),
                        ...subjects.map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text('${s['code']} - ${s['name']}', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Academic Class (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Class'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / All Classes', overflow: TextOverflow.ellipsis)),
                        ...classes.map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text('${c['name']} (${c['section']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedClassId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: 'Room / Venue (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Room'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None / Virtual', overflow: TextOverflow.ellipsis)),
                        ...rooms.map((r) => DropdownMenuItem(
                          value: r['id'].toString(),
                          child: Text('${r['code']} (${r['name']})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedRoomId = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final start = startCtrl.text.trim();
                  final end = endCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);

                  if (start.isEmpty || end.isEmpty || selectedFacultyId == null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Faculty, start time, and end time are required')));
                    return;
                  }
                  if (start.compareTo(end) >= 0) {
                    messenger.showSnackBar(const SnackBar(content: Text('Start time must precede end time')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).updateSchedule(scheduleId, {
                      'facultyId': selectedFacultyId,
                      'dayOfWeek': selectedDay,
                      'startTime': start,
                      'endTime': end,
                      'subjectId': selectedSubjectId,
                      'classId': selectedClassId,
                      'roomId': selectedRoomId,
                    });
                    ref.invalidate(adminSchedulesProvider(null));
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(const SnackBar(content: Text('Timetable slot updated successfully')));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Schedule Conflict / Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CHANGE REQUESTS TAB (PHASE 10)
  // ==========================================
  Widget _buildChangeRequestsTab(ThemeData theme) {
    final filter = AdminChangeRequestsFilter(
      status: _selectedChangeRequestStatus,
      category: _selectedChangeRequestCategory,
    );
    final requestsAsync = ref.watch(adminChangeRequestsProvider(filter));
    final pendingCount = ref.watch(adminPendingChangeRequestsCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Filter Bar
          CampusGlassPanel(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedChangeRequestStatus == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedChangeRequestStatus = null);
                    },
                  ),
                  ChoiceChip(
                    label: Text('Pending ($pendingCount)'),
                    selected: _selectedChangeRequestStatus == 'PENDING',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedChangeRequestStatus = 'PENDING');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Approved'),
                    selected: _selectedChangeRequestStatus == 'APPROVED',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedChangeRequestStatus = 'APPROVED');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Rejected'),
                    selected: _selectedChangeRequestStatus == 'REJECTED',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedChangeRequestStatus = 'REJECTED');
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  DropdownButton<String?>(
                    value: _selectedChangeRequestCategory,
                    underline: const SizedBox(),
                    hint: const Text('All Categories', style: TextStyle(fontSize: 13)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Categories')),
                      DropdownMenuItem(value: 'PERSONAL', child: Text('Personal Info')),
                      DropdownMenuItem(value: 'CONTACT', child: Text('Contact & Address')),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency Contacts')),
                      DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic Identity')),
                      DropdownMenuItem(value: 'CAREER', child: Text('Career Profile')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedChangeRequestCategory = val);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.invalidate(adminChangeRequestsProvider);
                      ref.invalidate(adminPendingChangeRequestsCountProvider);
                    },
                  ),
                ],
              ),
          ),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load change requests',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check connection or selected filters and try again.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(adminChangeRequestsProvider);
                          ref.invalidate(adminPendingChangeRequestsCountProvider);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (result) {
                final items = (result['items'] as List<dynamic>?) ?? [];
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No Profile Change Requests',
                    description: 'No student change requests match the selected status and category filters.',
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = items[index] as Map<String, dynamic>;
                    final student = req['student'] as Map<String, dynamic>? ?? {};
                    final dept = student['department'] as Map<String, dynamic>?;
                    final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
                    final rollNo = student['roll_number'] ?? 'No Roll No';
                    final deptName = dept?['name'] ?? dept?['code'] ?? 'No Dept';
                    final status = (req['status'] as String?) ?? 'PENDING';
                    final category = (req['category'] as String?) ?? 'GENERAL';
                    final field = (req['field'] as String?) ?? '';
                    final currentVal = (req['current_value'] as String?) ?? 'Not set';
                    final requestedVal = (req['requested_value'] as String?) ?? '';
                    final reason = (req['reason'] as String?) ?? '';
                    final reviewComment = req['review_comment'] as String?;
                    final reviewer = req['reviewer'] as Map<String, dynamic>?;

                    return CampusGlassPanel(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Header Row: Student Profile & Badges
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                  child: Text(
                                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName.isNotEmpty ? studentName : 'Unknown Student',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
                                        softWrap: true,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$rollNo • $deptName',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    AdminStatusChip(status: category),
                                    AdminStatusChip(status: status),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            // Field Name Badge
                            Row(
                              children: [
                                Text(
                                  'Field Requested: ',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    field,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Diff Comparison Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CURRENT VALUE',
                                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentVal,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurfaceVariant,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary, size: 20),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'REQUESTED CORRECTION',
                                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          requestedVal,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.format_quote_rounded, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Reason: $reason',
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Review history if not pending
                            if (status != 'PENDING') ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (status == 'APPROVED' ? Colors.green : Colors.red).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (status == 'APPROVED' ? Colors.green : Colors.red).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      status == 'APPROVED' ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      size: 16,
                                      color: status == 'APPROVED' ? Colors.green : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${status == 'APPROVED' ? 'Approved' : 'Rejected'}${reviewer != null ? ' by ${reviewer['first_name']} ${reviewer['last_name']}' : ''}${reviewComment != null && reviewComment.isNotEmpty ? ': "$reviewComment"' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: status == 'APPROVED' ? Colors.green : Colors.redAccent,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Action buttons if PENDING
                            if (status == 'PENDING') ...[
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showRejectChangeRequestDialog(context, req),
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: () => _showApproveChangeRequestDialog(context, req),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve & Apply'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveChangeRequestDialog(BuildContext context, Map<String, dynamic> req) {
    final commentCtrl = TextEditingController();
    final student = req['student'] as Map<String, dynamic>? ?? {};
    final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    final field = req['field'] ?? '';
    final requestedVal = req['requested_value'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Approve Profile Change',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve updating "$field" to "$requestedVal" for $studentName?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will immediately update the official institutional records in PostgreSQL and write an immutable audit log.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Reviewer Comment (Optional)',
                hintText: 'e.g. Verified with original certificates',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () async {
              final comment = commentCtrl.text.trim();
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(adminRemoteDataSourceProvider).approveChangeRequest(
                  req['id'],
                  reviewComment: comment.isNotEmpty ? comment : null,
                );
                ref.invalidate(adminChangeRequestsProvider);
                ref.invalidate(adminPendingChangeRequestsCountProvider);
                ref.invalidate(adminUsersProvider);
                ref.invalidate(adminAuditReportsProvider);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Change request approved and applied to official records!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Approval failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _showRejectChangeRequestDialog(BuildContext context, Map<String, dynamic> req) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final student = req['student'] as Map<String, dynamic>? ?? {};
    final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    final field = req['field'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reject Profile Change',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject the request to change "$field" for $studentName?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide a clear reason. The student will be notified with this reason.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Supporting documentation was illegible or invalid',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(adminRemoteDataSourceProvider).rejectChangeRequest(
                  req['id'],
                  rejectionReason: reason,
                );
                ref.invalidate(adminChangeRequestsProvider);
                ref.invalidate(adminPendingChangeRequestsCountProvider);
                ref.invalidate(adminAuditReportsProvider);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Change request rejected.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Rejection failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }
}

class _UserStatusSwitch extends StatefulWidget {
  final String userId;
  final bool initialActive;
  final WidgetRef ref;

  const _UserStatusSwitch({
    required this.userId,
    required this.initialActive,
    required this.ref,
  });

  @override
  State<_UserStatusSwitch> createState() => _UserStatusSwitchState();
}

class _UserStatusSwitchState extends State<_UserStatusSwitch> {
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.initialActive;
  }

  @override
  void didUpdateWidget(covariant _UserStatusSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialActive != widget.initialActive && !_isLoading) {
      _isActive = widget.initialActive;
    }
  }

  Future<void> _toggleStatus(bool value) async {
    final previousState = _isActive;
    setState(() {
      _isActive = value;
      _isLoading = true;
    });

    try {
      await widget.ref.read(adminRemoteDataSourceProvider).updateUserStatus(widget.userId, value);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'User account activated' : 'User account suspended'),
            duration: const Duration(seconds: 2),
            backgroundColor: value ? Colors.green.shade700 : Colors.orange.shade800,
          ),
        );
      }
      widget.ref.invalidate(adminUsersProvider);
      widget.ref.invalidate(adminMetricsProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActive = previousState;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: _isActive,
        activeThumbColor: Colors.green,
        onChanged: _isLoading ? null : (val) => _toggleStatus(val),
      ),
    );
  }
}
