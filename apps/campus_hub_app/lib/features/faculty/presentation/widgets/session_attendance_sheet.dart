import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/faculty_models.dart';
import '../controllers/faculty_controller.dart';
import '../../../../core/constants/api_endpoints.dart';

enum SaveState { idle, saving, saved, error }

class SessionAttendanceSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;

  const SessionAttendanceSheet({
    super.key,
    required this.sessionId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SessionAttendanceSheet(
        sessionId: sessionId,
        subjectId: subjectId,
        subjectCode: subjectCode,
        subjectName: subjectName,
      ),
    );
  }

  @override
  ConsumerState<SessionAttendanceSheet> createState() =>
      _SessionAttendanceSheetState();
}

class _SessionAttendanceSheetState
    extends ConsumerState<SessionAttendanceSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String?
      _statusFilter; // null = all, or 'PRESENT', 'ABSENT', 'UNMARKED', 'LATE', 'EXCUSED'

  // Local optimistic state for immediate responsive feedback
  final Map<String, String> _studentStatus = {};
  final Map<String, SaveState> _studentSaveState = {};
  final Map<String, String?> _studentRemarks = {};
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncStateWithData(SessionAttendanceDetail detail) {
    for (final s in detail.students) {
      if (!_studentStatus.containsKey(s.id)) {
        _studentStatus[s.id] = s.status;
        _studentSaveState[s.id] = SaveState.saved;
        _studentRemarks[s.id] = s.remarks;
      }
    }
  }

  Future<void> _updateStudentStatus({
    required EnrolledAttendanceStudent student,
    required String newStatus,
    required bool isLocked,
  }) async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Session is locked. Unlock to modify attendance records.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _studentStatus[student.id] = newStatus;
      _studentSaveState[student.id] = SaveState.saving;
    });

    try {
      if (student.recordId != null && student.recordId!.isNotEmpty) {
        final ok = await ref
            .read(facultyControllerProvider.notifier)
            .updateAttendanceRecord(
              sessionId: widget.sessionId,
              recordId: student.recordId!,
              status: newStatus,
              remarks: _studentRemarks[student.id],
            );
        if (mounted) {
          setState(() {
            _studentSaveState[student.id] =
                ok ? SaveState.saved : SaveState.error;
          });
        }
      } else {
        // No recordId exists yet; trigger bulk save for this student
        final ok = await ref
            .read(facultyControllerProvider.notifier)
            .bulkRecordAttendance(
          sessionId: widget.sessionId,
          records: [
            {
              'studentId': student.id,
              'status': newStatus,
              if (_studentRemarks[student.id] != null)
                'remarks': _studentRemarks[student.id],
            }
          ],
        );
        if (mounted) {
          setState(() {
            _studentSaveState[student.id] =
                ok ? SaveState.saved : SaveState.error;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _studentSaveState[student.id] = SaveState.error;
        });
      }
    }
  }

  Future<void> _markAllPresent(
      List<EnrolledAttendanceStudent> students, bool isLocked) async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Session is locked. Unlock to modify attendance records.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      for (final s in students) {
        _studentStatus[s.id] = 'PRESENT';
        _studentSaveState[s.id] = SaveState.saving;
      }
    });

    final records = students
        .map((s) => {
              'studentId': s.id,
              'status': 'PRESENT',
            })
        .toList();

    final ok =
        await ref.read(facultyControllerProvider.notifier).bulkRecordAttendance(
              sessionId: widget.sessionId,
              records: records,
            );

    if (mounted) {
      setState(() {
        for (final s in students) {
          _studentSaveState[s.id] = ok ? SaveState.saved : SaveState.error;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'All students marked Present'
              : 'Failed to save attendance records'),
          backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleLock(bool currentLocked) async {
    final newLock = !currentLocked;
    final ok =
        await ref.read(facultyControllerProvider.notifier).toggleSessionLock(
              sessionId: widget.sessionId,
              lock: newLock,
            );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (newLock
                    ? 'Session locked. Edits disabled.'
                    : 'Session unlocked for editing.')
                : 'Failed to update session lock state.',
          ),
          backgroundColor: ok
              ? (newLock ? Colors.amber.shade900 : Colors.teal.shade700)
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(sessionAttendanceProvider(widget.sessionId));

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return sessionAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load session attendance: $err'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(
                        sessionAttendanceProvider(widget.sessionId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (detail) {
            _syncStateWithData(detail);

            final isLocked = detail.session.status.toUpperCase() == 'LOCKED';

            // Recalculate live counts based on local status
            int livePresent = 0;
            int liveAbsent = 0;
            int liveLate = 0;
            int liveExcused = 0;
            int liveUnmarked = 0;

            for (final s in detail.students) {
              final st = _studentStatus[s.id] ?? s.status;
              switch (st.toUpperCase()) {
                case 'PRESENT':
                  livePresent++;
                  break;
                case 'ABSENT':
                  liveAbsent++;
                  break;
                case 'LATE':
                  liveLate++;
                  break;
                case 'EXCUSED':
                  liveExcused++;
                  break;
                default:
                  liveUnmarked++;
                  break;
              }
            }

            final total = detail.students.length;

            // Filter students
            final filteredStudents = detail.students.where((s) {
              final st = _studentStatus[s.id] ?? s.status;
              if (_statusFilter != null && st.toUpperCase() != _statusFilter) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final matchName = s.name.toLowerCase().contains(_searchQuery);
                final matchRoll =
                    s.rollNumber.toLowerCase().contains(_searchQuery);
                final matchDept =
                    s.department?.toLowerCase().contains(_searchQuery) ?? false;
                return matchName || matchRoll || matchDept;
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Top Sheet Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Top Header Row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.how_to_reg,
                            color: Colors.teal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.subjectCode} • Section ${detail.session.section}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${detail.session.sessionDate}${detail.session.topic != null ? ' • ${detail.session.topic}' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Lock session button & badge
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _toggleLock(isLocked),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isLocked
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLocked ? Icons.lock : Icons.lock_open,
                                  size: 14,
                                  color: isLocked
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLocked ? 'LOCKED' : 'OPEN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Sticky Summary Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildMetricBadge('Total', total, Colors.blueGrey),
                          const SizedBox(width: 8),
                          _buildMetricBadge(
                              'Present', livePresent, Colors.green),
                          const SizedBox(width: 8),
                          _buildMetricBadge('Absent', liveAbsent, Colors.red),
                          const SizedBox(width: 8),
                          _buildMetricBadge('Late', liveLate, Colors.orange),
                          const SizedBox(width: 8),
                          _buildMetricBadge(
                              'Excused', liveExcused, Colors.purple),
                          const SizedBox(width: 8),
                          _buildMetricBadge(
                              'Unmarked', liveUnmarked, Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Fast Action & Search Bar Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Search enrolled students...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  prefixIcon:
                                      const Icon(Icons.search, size: 18),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 16),
                                          onPressed: () => _searchCtrl.clear(),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('Mark All Present',
                                style: TextStyle(fontSize: 12)),
                            onPressed: isLocked
                                ? null
                                : () =>
                                    _markAllPresent(detail.students, isLocked),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Student Roster
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No enrolled students matching "$_searchQuery"'
                                  : 'No students enrolled in this subject for this term & section.',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: filteredStudents.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final student = filteredStudents[idx];
                            final currentStatus =
                                _studentStatus[student.id] ?? student.status;
                            final saveState = _studentSaveState[student.id] ??
                                SaveState.saved;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        Colors.blue.withValues(alpha: 0.12),
                                    backgroundImage: student.avatarUrl !=
                                                null &&
                                            student.avatarUrl!.isNotEmpty
                                        ? NetworkImage(ApiEndpoints.resolveUrl(
                                            student.avatarUrl!))
                                        : null,
                                    child: student.avatarUrl == null ||
                                            student.avatarUrl!.isEmpty
                                        ? Text(
                                            student.name.isNotEmpty
                                                ? student.name[0].toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                              fontSize: 13,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Student Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                student.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _buildSaveIndicator(saveState),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${student.rollNumber}${student.department != null ? ' • ${student.department}' : ''}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Toggle: [Present] [Absent] [Late] [Excused]
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusButton(
                                        label: 'P',
                                        fullLabel: 'Present',
                                        isSelected:
                                            currentStatus.toUpperCase() ==
                                                'PRESENT',
                                        selectedColor: Colors.green,
                                        isLocked: isLocked,
                                        onTap: () => _updateStudentStatus(
                                          student: student,
                                          newStatus: 'PRESENT',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildStatusButton(
                                        label: 'A',
                                        fullLabel: 'Absent',
                                        isSelected:
                                            currentStatus.toUpperCase() ==
                                                'ABSENT',
                                        selectedColor: Colors.red,
                                        isLocked: isLocked,
                                        onTap: () => _updateStudentStatus(
                                          student: student,
                                          newStatus: 'ABSENT',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildStatusButton(
                                        label: 'L',
                                        fullLabel: 'Late',
                                        isSelected:
                                            currentStatus.toUpperCase() ==
                                                'LATE',
                                        selectedColor: Colors.orange,
                                        isLocked: isLocked,
                                        onTap: () => _updateStudentStatus(
                                          student: student,
                                          newStatus: 'LATE',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildStatusButton(
                                        label: 'E',
                                        fullLabel: 'Excused',
                                        isSelected:
                                            currentStatus.toUpperCase() ==
                                                'EXCUSED',
                                        selectedColor: Colors.purple,
                                        isLocked: isLocked,
                                        onTap: () => _updateStudentStatus(
                                          student: student,
                                          newStatus: 'EXCUSED',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                    ],
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
        );
      },
    );
  }

  Widget _buildMetricBadge(String label, int count, Color color) {
    final isSelected = _statusFilter == label.toUpperCase();

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (_statusFilter == label.toUpperCase()) {
              _statusFilter = null;
            } else if (label.toUpperCase() != 'TOTAL') {
              _statusFilter = label.toUpperCase();
            } else {
              _statusFilter = null;
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color is MaterialColor ? color.shade800 : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color is MaterialColor ? color.shade800 : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required String fullLabel,
    required bool isSelected,
    required Color selectedColor,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : selectedColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : selectedColor.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : selectedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveIndicator(SaveState state) {
    switch (state) {
      case SaveState.saving:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 4),
            Text('Saving...',
                style: TextStyle(fontSize: 10, color: Colors.blue)),
          ],
        );
      case SaveState.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: Colors.green),
            SizedBox(width: 2),
            Text('Saved', style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        );
      case SaveState.error:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 12, color: Colors.red),
            SizedBox(width: 2),
            Text('Retry',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ],
        );
      case SaveState.idle:
        return const SizedBox.shrink();
    }
  }
}
