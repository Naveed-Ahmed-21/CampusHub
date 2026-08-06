import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';

class PublicPortfolioView extends ConsumerWidget {
  final String identifier;

  const PublicPortfolioView({super.key, required this.identifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(publicPortfolioProvider(identifier));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Portfolio'),
      ),
      body: portfolioAsync.when(
        data: (portfolio) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(
                          portfolio.userName.isNotEmpty ? portfolio.userName[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(portfolio.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (portfolio.departmentName != null)
                        Text(portfolio.departmentName!, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      const SizedBox(height: 8),
                      if (portfolio.cgpa > 0)
                        Chip(
                          label: Text('CGPA: ${portfolio.cgpa.toStringAsFixed(2)}'),
                          backgroundColor: Colors.teal.shade50,
                          labelStyle: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (portfolio.bio != null) ...[
                  const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(portfolio.bio!, style: TextStyle(color: Colors.grey.shade800)),
                  const SizedBox(height: 20),
                ],

                // Social Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (portfolio.githubUrl != null)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                      ),
                    const SizedBox(width: 8),
                    if (portfolio.linkedinUrl != null)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.work),
                        label: const Text('LinkedIn'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Projects
                if (portfolio.projects.isNotEmpty) ...[
                  const Text('Featured Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...portfolio.projects.map((proj) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(proj.description ?? ''),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Skills
                if (portfolio.skills.isNotEmpty) ...[
                  const Text('Technical Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: portfolio.skills.map((s) {
                      return Chip(
                        label: Text('${s.skillName} • ${s.proficiency}'),
                        backgroundColor: Colors.indigo.shade50,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Public Profile Error: $err')),
      ),
    );
  }
}
