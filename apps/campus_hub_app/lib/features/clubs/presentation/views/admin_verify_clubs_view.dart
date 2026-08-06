import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clubs_repository.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club ${status == 'APPROVED' ? 'Approved' : 'Rejected'} successfully!'),
            backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingClubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Club Verifications'),
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
                          style: const TextStyle(color: Colors.black87),
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
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            onPressed: () => _verify(context, ref, club.id, 'REJECTED'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve Club'),
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading pending clubs: $err'),
        ),
      ),
    );
  }
}
