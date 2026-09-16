import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/academics_controller.dart';
import '../../domain/models/academic_models.dart';
import '../../../chat/data/chat_repository.dart';

class FacultyDirectoryView extends ConsumerStatefulWidget {
  const FacultyDirectoryView({super.key});

  @override
  ConsumerState<FacultyDirectoryView> createState() => _FacultyDirectoryViewState();
}

class _FacultyDirectoryViewState extends ConsumerState<FacultyDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _messageFaculty(BuildContext context, String facultyUserId) async {
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

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final facultyListAsync = ref.watch(academicFacultyDirectoryProvider(_query.isEmpty ? null : _query));

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
              hintText: 'Search faculty by name, specialization, or department...',
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
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                                child: Text(
                                  fac.name.isNotEmpty ? fac.name[0].toUpperCase() : 'F',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fac.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${fac.designation} • ${fac.department}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
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
                              const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Text(fac.officeRoom, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 16, color: Colors.orange),
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
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              FilledButton.icon(
                                onPressed: () => _messageFaculty(context, fac.id),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Send Message', style: TextStyle(fontSize: 12)),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
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
          ),
        ),
      ],
    );
  }
}
