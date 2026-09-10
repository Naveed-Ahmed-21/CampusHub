import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> pillars = [
      {
        'title': 'Academic Collaboration',
        'desc': 'Bridge classroom learning with active peer discussion, lecture notes, faculty course channels, and subject-specific forums.',
        'icon': Icons.menu_book_rounded,
        'color': Colors.indigo,
      },
      {
        'title': 'Student Clubs & Community',
        'desc': 'Discover both department-specific technical chapters and cross-campus cultural, coding, and sports organizations.',
        'icon': Icons.diversity_3_rounded,
        'color': Colors.deepOrange,
      },
      {
        'title': 'AI Career Pathfinder',
        'desc': 'Personalized engineering curriculum roadmaps, adaptive skill milestones, checkpoint quizzes, and placement prep.',
        'icon': Icons.rocket_launch_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Real-Time Connectivity',
        'desc': 'Sub-second real-time messaging, instant club announcements, live notifications, and verified campus networking.',
        'icon': Icons.bolt_rounded,
        'color': Colors.amber.shade800,
      },
    ];

    final List<String> supportedDepts = [
      'Computer Science & Engineering (CSE)',
      'Information Technology (IT)',
      'Artificial Intelligence & Data Science (AI&DS)',
      'AI & Machine Learning (AIML)',
      'Electronics & Communication Engineering (ECE)',
      'Electrical & Electronics Engineering (EEE)',
      'Mechanical Engineering (MECH)',
      'Civil Engineering (CIVIL)',
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('About CampusHub'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Header & Branding Card
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.school, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'CampusHub',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version 1.0.0 (Build 2026.08)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The Unified Higher-Education Campus Collaboration Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Mission & Vision
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_circle_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Our Mission',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CampusHub was designed to eliminate information silos across university departments. By unifying academic coursework, student organization activities, placement training, and peer discovery into one cohesive mobile and web experience, we empower collegiate engineering communities to build, learn, and grow together.',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4 Core Ecosystem Pillars
          Text(
            'Core Ecosystem Pillars',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pillars.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (p['color'] as Color).withValues(alpha: 0.15),
                      child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['desc'] as String,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 18),

          // Supported Engineering Departments
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.domain, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Supported Academic Branches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...supportedDepts.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Tech Architecture & Privacy
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Privacy & Institutional Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CampusHub utilizes industry-standard cryptographic token sessions (JWT), parameterized SQL queries via Prisma, and isolated role-based permissions (Student, Faculty, Placement Officer, Club Admin). Your personal data is never sold or shared with commercial tracking networks.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Open Source Licenses Button
          OutlinedButton.icon(
            icon: const Icon(Icons.code, size: 18),
            label: const Text('Open Source Licenses & Attribution'),
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'CampusHub',
                applicationVersion: '1.0.0 (Build 2026.08)',
                applicationLegalese: 'Copyright © 2026 CampusHub Contributors. All rights reserved.',
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
