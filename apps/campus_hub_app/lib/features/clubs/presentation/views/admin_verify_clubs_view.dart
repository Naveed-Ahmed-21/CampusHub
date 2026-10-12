import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/campus_top_notification.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../data/clubs_repository.dart';
import '../../domain/club_models.dart';
import '../providers/club_provider.dart';

class AdminVerifyClubsView extends ConsumerWidget {
  const AdminVerifyClubsView({super.key});

  Future<void> _verify(BuildContext context, WidgetRef ref, String clubId, String status) async {
    String? reason;
    if (status == 'REJECTED') {
      final textController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject Club Request'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              hintText: 'e.g. Insufficient details provided',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      reason = textController.text.trim();
    }

    try {
      final repo = ref.read(clubsRepositoryProvider);
      await repo.verifyClub(clubId, status, rejectionReason: reason);
      ref.invalidate(pendingClubsProvider);
      ref.invalidate(approvedClubsProvider);

      if (context.mounted) {
        if (status == 'APPROVED') {
          CampusTopNotification.showSuccess(
            context,
            title: 'Club Approved',
            message: 'Club has been verified and is now live on CampusHub.',
          );
        } else {
          CampusTopNotification.showNotice(
            context,
            title: 'Club Rejected',
            message: 'Club proposal was rejected.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CampusTopNotification.showError(
          context,
          title: 'Verification Failed',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showClubDetailDialog(BuildContext context, WidgetRef ref, Club club) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            CampusAvatar(
              imageUrl: club.logoUrl,
              name: club.name,
              radius: 24,
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
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          club.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(club.isCrossDepartment ? Icons.public : Icons.domain, size: 14),
                      label: Text(
                        club.isCrossDepartment ? 'Cross-Department' : 'Dept-Only',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 14),
                      label: Text('${club.memberCount} Members', style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.close, color: Colors.red, size: 16),
            label: const Text('Reject', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _verify(context, ref, club.id, 'REJECTED');
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve Club'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _verify(context, ref, club.id, 'APPROVED');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pendingAsync = ref.watch(pendingClubsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CampusAppBar(
          leading: CampusBackButton(),
          title: 'Club Verifications',
          subtitle: 'Administrative Review',
        ),
      body: pendingAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending club requests!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showClubDetailDialog(context, ref, club),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                club.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                club.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            ),
                          ],
                        ),
                        if (club.description != null && club.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            club.description!,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              avatar: Icon(
                                club.isCrossDepartment ? Icons.public : Icons.apartment,
                                size: 16,
                              ),
                              label: Text(
                                club.isCrossDepartment
                                    ? 'Cross-Department'
                                    : 'Department Restricted',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            if (club.creatorName != null)
                              Chip(
                                avatar: const Icon(Icons.person_outline, size: 16),
                                label: Text(
                                  'By: ${club.creatorName}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('View Details'),
                              onPressed: () => _showClubDetailDialog(context, ref, club),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                              onPressed: () => _verify(context, ref, club.id, 'REJECTED'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _verify(context, ref, club.id, 'APPROVED'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading pending clubs: $err'),
        ),
      ),
    ),
  );
}
}
