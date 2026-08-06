import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';

class CareerHubView extends ConsumerStatefulWidget {
  const CareerHubView({super.key});

  @override
  ConsumerState<CareerHubView> createState() => _CareerHubViewState();
}

class _CareerHubViewState extends ConsumerState<CareerHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Weekly Goal'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Goal Title',
            hintText: 'e.g. Complete 5 LeetCode Medium problems',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final repo = ref.read(careerRepositoryProvider);
              await repo.createWeeklyGoal(titleController.text.trim());
              ref.invalidate(weeklyGoalsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  void _showSubmitProjectDialog(MiniProjectModel project) {
    final repoController = TextEditingController();
    final demoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Submit Solution: ${project.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repoController,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository URL',
                hintText: 'https://github.com/...',
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: demoController,
              decoration: const InputDecoration(
                labelText: 'Optional Live Demo URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (repoController.text.trim().isEmpty) return;
              final repo = ref.read(careerRepositoryProvider);
              await repo.submitMiniProject(
                project.id,
                repoController.text.trim(),
                liveDemoUrl: demoController.text.trim().isEmpty ? null : demoController.text.trim(),
              );
              ref.invalidate(miniProjectsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Submit Solution'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Hub & Prep'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Roadmaps'),
            Tab(icon: Icon(Icons.task_alt), text: 'Weekly Goals'),
            Tab(icon: Icon(Icons.menu_book), text: 'Resources'),
            Tab(icon: Icon(Icons.description), text: 'Resume Tips'),
            Tab(icon: Icon(Icons.school), text: 'Placement Prep'),
            Tab(icon: Icon(Icons.rocket_launch), text: 'Mini Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoadmapsTab(),
          _buildWeeklyGoalsTab(),
          _buildLearningResourcesTab(),
          _buildResumeTipsTab(),
          _buildPlacementPrepTab(),
          _buildMiniProjectsTab(),
        ],
      ),
    );
  }

  // 1. Roadmaps & Progress Tracking Tab
  Widget _buildRoadmapsTab() {
    final roadmapsAsync = ref.watch(careerRoadmapsProvider);
    final progressAsync = ref.watch(userCareerProgressProvider);

    return roadmapsAsync.when(
      data: (roadmaps) {
        final completedNodeIds = (progressAsync.valueOrNull?['completedNodeIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};

        if (roadmaps.isEmpty) {
          return const Center(child: Text('No career roadmaps available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roadmaps.length,
          itemBuilder: (ctx, idx) {
            final roadmap = roadmaps[idx];
            final nodes = roadmap.nodes;
            final completedCount = nodes.where((n) => completedNodeIds.contains(n.id)).length;
            final percent = nodes.isNotEmpty ? (completedCount / nodes.length) : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(
                    roadmap.level == 'Beginner' ? Icons.directions_walk : Icons.directions_run,
                    color: Colors.indigo,
                  ),
                ),
                title: Text(roadmap.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${roadmap.category} • ${roadmap.level} • ${roadmap.estimatedMonths} Months'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.indigo,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}% Completed ($completedCount / ${nodes.length} Milestones)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roadmap.description, style: TextStyle(color: Colors.grey.shade800)),
                        const SizedBox(height: 12),
                        const Text('Milestone Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...nodes.map((node) {
                          final isDone = completedNodeIds.contains(node.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(node.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: node.description != null ? Text(node.description!) : null,
                            value: isDone,
                            onChanged: (val) async {
                              final repo = ref.read(careerRepositoryProvider);
                              await repo.toggleNodeProgress(node.id, val ?? false);
                              ref.invalidate(userCareerProgressProvider);
                              ref.invalidate(careerRoadmapsProvider);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
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
              const Text('Could not load career roadmaps', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(careerRoadmapsProvider);
                  ref.invalidate(userCareerProgressProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Weekly Goals Tab
  Widget _buildWeeklyGoalsTab() {
    final goalsAsync = ref.watch(weeklyGoalsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
        backgroundColor: Colors.teal,
      ),
      body: goalsAsync.when(
        data: (goals) {
          final completedGoals = goals.where((g) => g.isCompleted).length;

          return Column(
            children: [
              // Goal Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.teal.shade50,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Progress Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('$completedGoals of ${goals.length} weekly goals achieved this week!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: goals.isEmpty
                    ? const Center(
                        child: Text('No weekly goals set yet. Tap "+ Add Goal" to start!'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: goals.length,
                        itemBuilder: (ctx, idx) {
                          final goal = goals[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: CheckboxListTile(
                              title: Text(
                                goal.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                  color: goal.isCompleted ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Target: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: goal.isCompleted,
                              onChanged: (val) async {
                                final repo = ref.read(careerRepositoryProvider);
                                await repo.toggleWeeklyGoal(goal.id, val ?? false);
                                ref.invalidate(weeklyGoalsProvider);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading goals: $err')),
      ),
    );
  }

  // 3. Learning Resources Tab
  Widget _buildLearningResourcesTab() {
    final roadmapsAsync = ref.watch(careerRoadmapsProvider);

    return roadmapsAsync.when(
      data: (roadmaps) {
        final allResources = roadmaps.expand((r) => r.nodes.expand((n) => n.resources)).toList();

        if (allResources.isEmpty) {
          return const Center(child: Text('No learning resources found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allResources.length,
          itemBuilder: (ctx, idx) {
            final res = allResources[idx];
            IconData typeIcon = Icons.article;
            Color typeColor = Colors.blue;

            if (res.type == 'VIDEO') {
              typeIcon = Icons.play_circle_fill;
              typeColor = Colors.red;
            } else if (res.type == 'PRACTICE') {
              typeIcon = Icons.code;
              typeColor = Colors.green;
            } else if (res.type == 'DOCS') {
              typeIcon = Icons.menu_book;
              typeColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withValues(alpha: 0.1),
                  child: Icon(typeIcon, color: typeColor),
                ),
                title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Type: ${res.type} • ${res.isFree ? 'Free' : 'Premium'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening resource: ${res.url}')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading resources: $err')),
    );
  }

  // 4. Resume Tips Tab
  Widget _buildResumeTipsTab() {
    final tipsAsync = ref.watch(resumeTipsProvider);

    return tipsAsync.when(
      data: (tips) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tips.length,
          itemBuilder: (ctx, idx) {
            final tip = tips[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tip.category,
                        style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(tip.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(tip.content, style: TextStyle(color: Colors.grey.shade800)),
                    if (tip.bulletPoints.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...tip.bulletPoints.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading tips: $err')),
    );
  }

  // 5. Placement Prep Tab
  Widget _buildPlacementPrepTab() {
    final prepAsync = ref.watch(placementPrepProvider);

    return prepAsync.when(
      data: (modules) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: modules.length,
          itemBuilder: (ctx, idx) {
            final mod = modules[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(mod.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Category: ${mod.category}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mod.contentItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Q: ${item['question'] ?? 'Question'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Approach: ${item['approach'] ?? ''}', style: TextStyle(color: Colors.grey.shade800)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading prep modules: $err')),
    );
  }

  // 6. Mini Projects Tab
  Widget _buildMiniProjectsTab() {
    final projectsAsync = ref.watch(miniProjectsProvider);

    return projectsAsync.when(
      data: (projects) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (ctx, idx) {
            final proj = projects[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(proj.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Chip(
                          label: Text(proj.difficulty),
                          backgroundColor: proj.difficulty == 'Beginner'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          labelStyle: TextStyle(
                            color: proj.difficulty == 'Beginner' ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(proj.problemStatement),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: proj.techStack
                          .map(
                            (tech) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tech, style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (proj.isSubmitted)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 4),
                              Text('Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _showSubmitProjectDialog(proj),
                            icon: const Icon(Icons.upload),
                            label: const Text('Submit Solution'),
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
      error: (err, stack) => Center(child: Text('Error loading projects: $err')),
    );
  }
}
