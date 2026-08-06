import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

class PlacementHubView extends ConsumerStatefulWidget {
  const PlacementHubView({super.key});

  @override
  ConsumerState<PlacementHubView> createState() => _PlacementHubViewState();
}

class _PlacementHubViewState extends ConsumerState<PlacementHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateDriveDialog() {
    final companyCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final ctcCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final cgpaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Placement Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Role Title (e.g. SDE-1)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctcCtrl,
                decoration: const InputDecoration(labelText: 'Package CTC (e.g. 12 LPA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Job Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cgpaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum CGPA Cutoff', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.trim().isEmpty || roleCtrl.text.trim().isEmpty) return;
              final repo = ref.read(placementRepositoryProvider);
              await repo.createDrive(
                companyName: companyCtrl.text.trim(),
                roleTitle: roleCtrl.text.trim(),
                packageCtc: ctcCtrl.text.trim(),
                location: locationCtrl.text.trim(),
                minCgpa: double.tryParse(cgpaCtrl.text.trim()) ?? 0.0,
                deadline: DateTime.now().add(const Duration(days: 14)).toIso8601String(),
              );
              ref.invalidate(placementDrivesProvider);
              ref.invalidate(officerDashboardProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Post Drive'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForDrive(PlacementDriveModel drive) async {
    try {
      final repo = ref.read(placementRepositoryProvider);
      await repo.applyForDrive(drive.id);
      ref.invalidate(studentDashboardProvider);
      ref.invalidate(placementDrivesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully applied for ${drive.companyName}!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _respondToOffer(String applicationId, String offerStatus) async {
    try {
      final repo = ref.read(placementRepositoryProvider);
      await repo.respondToOffer(applicationId, offerStatus);
      ref.invalidate(studentDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer $offerStatus successfully!'),
            backgroundColor: offerStatus == 'ACCEPTED' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement & Career Drives'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Company Drives'),
            Tab(icon: Icon(Icons.person), text: 'My Applications'),
            Tab(icon: Icon(Icons.dashboard), text: 'Officer Hub'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompanyDrivesTab(),
          _buildStudentDashboardTab(),
          _buildOfficerDashboardTab(),
        ],
      ),
    );
  }

  // 1. Company Drives Tab
  Widget _buildCompanyDrivesTab() {
    final drivesAsync = ref.watch(placementDrivesProvider);
    final studentDashAsync = ref.watch(studentDashboardProvider);

    final appliedDriveIds = ((studentDashAsync.valueOrNull?['myApplications'] as List<dynamic>?) ?? [])
        .map((a) => a['drive_id'] as String? ?? '')
        .toSet();

    return drivesAsync.when(
      data: (drives) {
        if (drives.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No placement drives posted yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drives.length,
          itemBuilder: (ctx, idx) {
            final drive = drives[idx];
            final isApplied = appliedDriveIds.contains(drive.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                drive.companyName.isNotEmpty ? drive.companyName[0] : 'C',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(drive.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(drive.roleTitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        if (drive.packageCtc != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              drive.packageCtc!,
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(drive.location ?? 'Bangalore / Remote', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.star_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Min CGPA: ${drive.minCgpa}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deadline: ${drive.deadline.day}/${drive.deadline.month}/${drive.deadline.year}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (isApplied)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Text('Applied', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: drive.isExpired ? null : () => _applyForDrive(drive),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: Text(drive.isExpired ? 'Expired' : 'Apply Now'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              const Text('Could not load placement drives', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(placementDrivesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Student Dashboard & Tracking Tab
  Widget _buildStudentDashboardTab() {
    final studentDashAsync = ref.watch(studentDashboardProvider);

    return studentDashAsync.when(
      data: (data) {
        final List rawApps = data['myApplications'] ?? [];
        final applications = rawApps.map((a) => PlacementApplicationModel.fromJson(a)).toList();
        final List rawOffers = data['myOffers'] ?? [];
        final offers = rawOffers.map((o) => PlacementApplicationModel.fromJson(o)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Offers Banner Section
            if (offers.isNotEmpty) ...[
              const Text('Job Offers Received 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...offers.map((offer) {
                return Card(
                  color: Colors.amber.shade50,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(offer.drive?.companyName ?? 'Company', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(offer.offerCtc ?? 'Package Offered', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Role: ${offer.drive?.roleTitle ?? 'Engineer'}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (offer.offerStatus == 'ACCEPTED')
                              const Chip(label: Text('Offer Accepted'), backgroundColor: Colors.greenAccent)
                            else ...[
                              OutlinedButton(
                                onPressed: () => _respondToOffer(offer.id, 'DECLINED'),
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _respondToOffer(offer.id, 'ACCEPTED'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Accept Offer'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            const Text('Application Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (applications.isEmpty)
              const Center(child: Text('You have not applied for any placement drives yet.'))
            else
              ...applications.map((app) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(app.drive?.companyName ?? 'Company', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Role: ${app.drive?.roleTitle} • Stage: ${app.status}'),
                    trailing: _buildStatusBadge(app.status),
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Could not load student dashboard'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(studentDashboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Officer Dashboard Tab
  Widget _buildOfficerDashboardTab() {
    final officerStatsAsync = ref.watch(officerDashboardProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDriveDialog,
        icon: const Icon(Icons.add),
        label: const Text('Post Drive'),
        backgroundColor: Colors.indigo,
      ),
      body: officerStatsAsync.when(
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Placement Officer Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatTile('Total Drives', '${stats['totalDrives'] ?? 0}', Icons.business, Colors.blue),
                  _buildStatTile('Active Drives', '${stats['activeDrives'] ?? 0}', Icons.work, Colors.green),
                  _buildStatTile('Applications', '${stats['totalApplications'] ?? 0}', Icons.assignment, Colors.orange),
                  _buildStatTile('Accepted Offers', '${stats['acceptedOffers'] ?? 0}', Icons.star, Colors.purple),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 48, color: Colors.indigo),
                const SizedBox(height: 12),
                const Text(
                  'Placement Officer Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Access restricted to Placement Officers & Admins or server connection error.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(officerDashboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 8),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'OFFERED') color = Colors.green;
    if (status == 'REJECTED') color = Colors.red;
    if (status == 'SHORTLISTED') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
