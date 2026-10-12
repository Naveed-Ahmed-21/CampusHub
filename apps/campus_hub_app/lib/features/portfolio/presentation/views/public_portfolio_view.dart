import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';

class PublicPortfolioView extends ConsumerWidget {
  final String identifier;

  const PublicPortfolioView({super.key, required this.identifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(publicPortfolioProvider(identifier));

    return Scaffold(
      appBar: const CampusAppBar(
        leading: CampusBackButton(),
        title: 'Public Portfolio',
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
                      CampusAvatar(
                        imageUrl: portfolio.avatarUrl,
                        name: portfolio.userName,
                        radius: 44,
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
                  children: [
                    if (portfolio.githubUrl != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.code, size: 16),
                          label: const Text('GitHub', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    if (portfolio.githubUrl != null && portfolio.linkedinUrl != null)
                      const SizedBox(width: 8),
                    if (portfolio.linkedinUrl != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.work, size: 16),
                          label: const Text('LinkedIn', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
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
