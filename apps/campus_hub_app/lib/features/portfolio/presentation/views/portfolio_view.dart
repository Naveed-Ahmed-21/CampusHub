import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_models.dart';
import 'public_portfolio_view.dart';

class PortfolioView extends ConsumerStatefulWidget {
  const PortfolioView({super.key});

  @override
  ConsumerState<PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends ConsumerState<PortfolioView> {
  void _showAddProjectDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final stackCtrl = TextEditingController();
    final repoCtrl = TextEditingController();
    final demoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: stackCtrl, decoration: const InputDecoration(labelText: 'Tech Stack (comma separated)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: repoCtrl, decoration: const InputDecoration(labelText: 'GitHub Repo URL', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: demoCtrl, decoration: const InputDecoration(labelText: 'Live Demo URL', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final repo = ref.read(portfolioRepositoryProvider);
              final stackList = stackCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

              await repo.addProject(
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                techStack: stackList,
                repoUrl: repoCtrl.text.trim().isEmpty ? null : repoCtrl.text.trim(),
                projectUrl: demoCtrl.text.trim().isEmpty ? null : demoCtrl.text.trim(),
              );

              ref.invalidate(userPortfolioProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    final skillCtrl = TextEditingController();
    String category = 'General';
    String proficiency = 'Intermediate';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: 'Skill Name (e.g. Flutter)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: proficiency,
              decoration: const InputDecoration(labelText: 'Proficiency', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                DropdownMenuItem(value: 'Expert', child: Text('Expert')),
              ],
              onChanged: (val) => proficiency = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (skillCtrl.text.trim().isEmpty) return;
              final repo = ref.read(portfolioRepositoryProvider);
              await repo.addSkill(
                skillName: skillCtrl.text.trim(),
                category: category,
                proficiency: proficiency,
              );
              ref.invalidate(userPortfolioProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add Skill'),
          ),
        ],
      ),
    );
  }

  void _showAddCertificateDialog() {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Certificate Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: issuerCtrl, decoration: const InputDecoration(labelText: 'Issuer (e.g. AWS)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Credential Verification URL', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || issuerCtrl.text.trim().isEmpty) return;
              final repo = ref.read(portfolioRepositoryProvider);
              await repo.addCertificate(
                title: titleCtrl.text.trim(),
                issuer: issuerCtrl.text.trim(),
                credentialUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
              );
              ref.invalidate(userPortfolioProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add Certificate'),
          ),
        ],
      ),
    );
  }

  void _showEditSocialsDialog(PortfolioModel portfolio) {
    final bioCtrl = TextEditingController(text: portfolio.bio);
    final githubCtrl = TextEditingController(text: portfolio.githubUrl);
    final linkedinCtrl = TextEditingController(text: portfolio.linkedinUrl);
    final websiteCtrl = TextEditingController(text: portfolio.websiteUrl);
    final resumeCtrl = TextEditingController(text: portfolio.resumeUrl);
    final cgpaCtrl = TextEditingController(text: portfolio.cgpa > 0 ? portfolio.cgpa.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Social Links & Bio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Short Bio', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: cgpaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CGPA', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: githubCtrl, decoration: const InputDecoration(labelText: 'GitHub Profile URL', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: linkedinCtrl, decoration: const InputDecoration(labelText: 'LinkedIn Profile URL', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: websiteCtrl, decoration: const InputDecoration(labelText: 'Personal Website URL', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: resumeCtrl, decoration: const InputDecoration(labelText: 'Resume PDF URL', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(portfolioRepositoryProvider);
              await repo.updatePortfolio(
                bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                cgpa: double.tryParse(cgpaCtrl.text.trim()) ?? 0.0,
                githubUrl: githubCtrl.text.trim().isEmpty ? null : githubCtrl.text.trim(),
                linkedinUrl: linkedinCtrl.text.trim().isEmpty ? null : linkedinCtrl.text.trim(),
                websiteUrl: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                resumeUrl: resumeCtrl.text.trim().isEmpty ? null : resumeCtrl.text.trim(),
              );
              ref.invalidate(userPortfolioProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(userPortfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userPortfolioProvider),
          ),
        ],
      ),
      body: portfolioAsync.when(
        data: (portfolio) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            portfolio.userName.isNotEmpty ? portfolio.userName[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(portfolio.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(portfolio.userEmail, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if (portfolio.bio != null) ...[
                          const SizedBox(height: 8),
                          Text(portfolio.bio!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showEditSocialsDialog(portfolio),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile & Links'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => PublicPortfolioView(identifier: portfolio.userId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Public View'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Projects Section
                _buildSectionHeader('Projects', _showAddProjectDialog),
                if (portfolio.projects.isEmpty)
                  const Text('No projects added yet.', style: TextStyle(color: Colors.grey))
                else
                  ...portfolio.projects.map((p) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.description ?? 'No description'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final repo = ref.read(portfolioRepositoryProvider);
                            await repo.deleteProject(p.id);
                            ref.invalidate(userPortfolioProvider);
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),

                // Skills Section
                _buildSectionHeader('Skills', _showAddSkillDialog),
                if (portfolio.skills.isEmpty)
                  const Text('No skills added yet.', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: portfolio.skills.map((s) {
                      return Chip(
                        label: Text('${s.skillName} • ${s.proficiency}'),
                        backgroundColor: Colors.teal.shade50,
                        onDeleted: () async {
                          final repo = ref.read(portfolioRepositoryProvider);
                          await repo.deleteSkill(s.id);
                          ref.invalidate(userPortfolioProvider);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // Certificates Section
                _buildSectionHeader('Certificates', _showAddCertificateDialog),
                if (portfolio.certificates.isEmpty)
                  const Text('No certificates added yet.', style: TextStyle(color: Colors.grey))
                else
                  ...portfolio.certificates.map((c) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: Colors.blue),
                        title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Issuer: ${c.issuer}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final repo = ref.read(portfolioRepositoryProvider);
                            await repo.deleteCertificate(c.id);
                            ref.invalidate(userPortfolioProvider);
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Portfolio Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal), onPressed: onAdd),
      ],
    );
  }
}
