import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpSupportView extends ConsumerStatefulWidget {
  const HelpSupportView({super.key});

  @override
  ConsumerState<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends ConsumerState<HelpSupportView> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'category': 'Account & Security',
      'icon': Icons.security,
      'items': [
        {
          'q': 'How do I reset my password or update login credentials?',
          'a': 'To reset your password, visit the login screen and tap "Forgot Password", or visit your Campus IT Administrator desk in the Admin Block with your student ID card.',
        },
        {
          'q': 'Why is my account verification status important?',
          'a': 'Verified accounts have verified student or faculty badges, ensuring trusted peer interactions, official club creation privileges, and placement portal access.',
        },
        {
          'q': 'Can I change my department or academic year?',
          'a': 'Your primary department is tied to your college registration. To request a department transfer update, submit an in-app ticket or contact the Academic Registrar.',
        },
      ],
    },
    {
      'category': 'Feed & Posts',
      'icon': Icons.dynamic_feed,
      'items': [
        {
          'q': 'How do the "For You", "My Department", and "Related" feeds differ?',
          'a': '"For You" presents campus-wide highlights, announcements, and trending discussions. "My Department" isolates official updates and queries within your major. "Related" surfaces relevant academic disciplines and inter-disciplinary posts.',
        },
        {
          'q': 'What are the rules for posting announcements?',
          'a': 'All posts must adhere to the CampusHub Student Code of Conduct. Harassment, spam, academic dishonesty, and commercial promotions without approval are strictly prohibited.',
        },
        {
          'q': 'Can I edit or delete a post after publishing?',
          'a': 'Yes, tap the three dots (⋮) on any post you authored to edit its text or remove it permanently from the campus feed.',
        },
      ],
    },
    {
      'category': 'Chat & Messaging',
      'icon': Icons.chat_bubble_outline,
      'items': [
        {
          'q': 'Why do only started conversations appear in my Messages tab?',
          'a': 'To keep your inbox clean and focused, the Messages screen displays only conversations that have actually begun. To start chatting with someone new, navigate to the Explore tab, search for the user, and tap the "Message" button.',
        },
        {
          'q': 'Are direct messages encrypted and private?',
          'a': 'Yes, direct messages are private between you and the recipient. Only members of a room can read messages sent in that channel.',
        },
        {
          'q': 'How do I create a study group chat?',
          'a': 'In the Messages screen, tap the floating "+" button and select "New Group Chat". Choose your participants and name your group.',
        },
      ],
    },
    {
      'category': 'Clubs & Events',
      'icon': Icons.groups_outlined,
      'items': [
        {
          'q': 'What is the difference between Department Clubs and Cross-Department Clubs?',
          'a': 'Department Clubs focus on specialized technical domains tied to a specific branch (e.g. ACM Student Chapter, Robotics Club). Cross-Department Clubs are open to students of all branches (e.g. Cultural, Coding, Debate, Sports). Both appear seamlessly in your Clubs screen.',
        },
        {
          'q': 'How do I register for campus hackathons and workshops?',
          'a': 'Navigate to the Clubs tab, open any active club or event card, and tap "Register" to reserve your spot.',
        },
      ],
    },
    {
      'category': 'Career Pathfinder & Placements',
      'icon': Icons.school_outlined,
      'items': [
        {
          'q': 'How does the AI Career Pathfinder determine my match score?',
          'a': 'The Pathfinder evaluates your college year, domain interest, math/theory preference, weekly hours commitment, and preferred stack to generate tailored curriculum milestones and checkpoint quizzes.',
        },
        {
          'q': 'Can I switch my active career roadmap at any time?',
          'a': 'Yes! Tap "Change Path" or retake the assessment in the Career Hub whenever your interests evolve.',
        },
      ],
    },
  ];

  void _showReportProblemModal() {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Bug Report';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Report a Problem / Send Feedback',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Our technical team reviews every report. Please include clear details.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                        DropdownMenuItem(value: 'Account / Auth Issue', child: Text('Account / Auth Issue')),
                        DropdownMenuItem(value: 'Feed & Content Concern', child: Text('Feed & Content Concern')),
                        DropdownMenuItem(value: 'Chat & Notifications', child: Text('Chat & Notifications')),
                        DropdownMenuItem(value: 'Career & Placement Feature', child: Text('Career & Placement Feature')),
                        DropdownMenuItem(value: 'General Feedback', child: Text('General Feedback')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of the issue',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe what happened, steps to reproduce, or your suggestion...',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (val) => (val == null || val.trim().length < 10)
                          ? 'Please provide at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Device: Mobile/Desktop Client | App: CampusHub v1.0.0 | Session: Verified',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(isSubmitting ? 'Submitting...' : 'Submit Support Ticket'),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);
                                await Future.delayed(const Duration(milliseconds: 700));
                                if (mounted && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  final ticketId =
                                      'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                  showDialog(
                                    context: context,
                                    builder: (doneCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Ticket Submitted'),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Thank you for helping us improve CampusHub. Your ticket has been registered successfully.',
                                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Tracking ID: $ticketId',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.pop(doneCtx),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredFaqs = _faqCategories.map((cat) {
      final items = (cat['items'] as List<Map<String, String>>).where((item) {
        if (_searchQuery.trim().isEmpty) return true;
        final q = item['q']!.toLowerCase();
        final a = item['a']!.toLowerCase();
        final search = _searchQuery.toLowerCase();
        return q.contains(search) || a.contains(search);
      }).toList();

      return {
        'category': cat['category'],
        'icon': cat['icon'],
        'items': items,
      };
    }).where((cat) => (cat['items'] as List).isNotEmpty).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search & Action Header
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'How can we help you today?',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search frequently asked questions or submit an in-app ticket to our support team.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search FAQs and answers...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action: Report a Problem
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.bug_report, color: theme.colorScheme.primary),
              ),
              title: const Text('Report an Issue or Send Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Found a bug or have a suggestion? Open an in-app ticket', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showReportProblemModal,
            ),
          ),
          const SizedBox(height: 20),

          // FAQs Section
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (filteredFaqs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No FAQs found matching "$_searchQuery".',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...filteredFaqs.map((cat) {
              final items = cat['items'] as List<Map<String, String>>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: ExpansionTile(
                  leading: Icon(cat['icon'] as IconData, color: theme.colorScheme.primary),
                  title: Text(
                    cat['category'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('${items.length} questions', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  children: items
                      .map((item) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['q']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['a']!,
                                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Campus IT Support Guidelines Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Campus IT & Admin Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For hardware connectivity on campus Wi-Fi, institutional email resets, and semester credential issues:',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('Location: Central Computing Center, 1st Floor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('Hours: Monday – Friday | 9:00 AM – 5:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
