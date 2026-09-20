import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/academics_controller.dart';
import '../../domain/models/academic_models.dart';
import '../../../chat/data/chat_repository.dart';

class FacultyDirectoryView extends ConsumerStatefulWidget {
  const FacultyDirectoryView({super.key});

  @override
  ConsumerState<FacultyDirectoryView> createState() =>
      _FacultyDirectoryViewState();
}

class _FacultyDirectoryViewState extends ConsumerState<FacultyDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _messageFaculty(
      BuildContext context, String facultyUserId) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final room = await chatRepo.getOrCreateDirectChat(facultyUserId);
      if (context.mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  void _showFacultyDetail(BuildContext context, AcademicFacultyFull fac) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/profile/${fac.id}');
                        },
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.blue.withValues(alpha: 0.15),
                          backgroundImage:
                              fac.avatarUrl != null && fac.avatarUrl!.isNotEmpty
                                  ? NetworkImage(
                                      ApiEndpoints.resolveUrl(fac.avatarUrl!))
                                  : null,
                          child: fac.avatarUrl == null || fac.avatarUrl!.isEmpty
                              ? Text(
                                  fac.name.isNotEmpty
                                      ? fac.name[0].toUpperCase()
                                      : 'F',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                context.push('/profile/${fac.id}');
                              },
                              child: Text(
                                fac.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${fac.designation} • ${fac.department}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (fac.qualification.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                fac.qualification,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                fac.specialization,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action buttons: View Profile and Send Message
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/profile/${fac.id}');
                          },
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text('View Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _messageFaculty(context, fac.id);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Contact & Office Information
                  Text(
                    'Contact & Availability',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    iconColor: Colors.redAccent,
                    label: 'Email Address',
                    value: fac.email.isNotEmpty ? fac.email : 'Not specified',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    icon: Icons.meeting_room_outlined,
                    iconColor: Colors.teal,
                    label: 'Office Location',
                    value: fac.officeRoom.isNotEmpty
                        ? fac.officeRoom
                        : 'Faculty Cabins',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    iconColor: Colors.orange,
                    label: 'Office Hours',
                    value: fac.officeHours.isNotEmpty
                        ? fac.officeHours
                        : 'By appointment',
                  ),
                  if (fac.bio.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'About',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fac.bio,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (fac.expertise.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Areas of Expertise',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fac.expertise.map((exp) {
                        return Chip(
                          label:
                              Text(exp, style: const TextStyle(fontSize: 12)),
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  ],
                  if (fac.publications.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Publications & Research (${fac.publications.length})',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...fac.publications.map((pub) {
                      final title =
                          pub['title'] ?? pub['name'] ?? 'Research Paper';
                      final year =
                          pub['year'] != null ? ' (${pub['year']})' : '';
                      final journal = pub['journal'] ?? pub['publisher'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.article_outlined,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$title$year',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  if (journal.toString().isNotEmpty)
                                    Text(
                                      journal.toString(),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final facultyListAsync = ref.watch(
        academicFacultyDirectoryProvider(_query.isEmpty ? null : _query));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty & Mentors Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, facultyListAsync, isDesktop: false),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: _buildBody(context, facultyListAsync, isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<AcademicFacultyFull>> facultyListAsync, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search faculty by name, specialization, or department...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() => _query = val.trim());
            },
          ),
        ),

        // Faculty Roster
        Expanded(
          child: AsyncValueWidget<List<AcademicFacultyFull>>(
            value: facultyListAsync,
            data: (facultyList) {
              if (facultyList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No faculty members found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 16,
                ),
                itemCount: facultyList.length,
                itemBuilder: (context, index) {
                  final fac = facultyList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showFacultyDetail(context, fac),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/profile/${fac.id}'),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        Colors.blue.withValues(alpha: 0.15),
                                    backgroundImage: fac.avatarUrl != null &&
                                            fac.avatarUrl!.isNotEmpty
                                        ? NetworkImage(ApiEndpoints.resolveUrl(
                                            fac.avatarUrl!))
                                        : null,
                                    child: fac.avatarUrl == null ||
                                            fac.avatarUrl!.isEmpty
                                        ? Text(
                                            fac.name.isNotEmpty
                                                ? fac.name[0].toUpperCase()
                                                : 'F',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            context.push('/profile/${fac.id}'),
                                        child: Text(
                                          fac.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${fac.designation} • ${fac.department}',
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        fac.specialization,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Office Room and Hours
                            Row(
                              children: [
                                const Icon(Icons.meeting_room_outlined,
                                    size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Text(fac.officeRoom,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    fac.officeHours,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Bottom Action: Direct Message
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fac.email,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _messageFaculty(context, fac.id),
                                  icon: const Icon(Icons.chat_bubble_outline,
                                      size: 16),
                                  label: const Text('Send Message',
                                      style: TextStyle(fontSize: 12)),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
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
          ),
        ),
      ],
    );
  }
}
