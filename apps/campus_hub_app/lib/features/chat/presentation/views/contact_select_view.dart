import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../utils/chat_navigation_helper.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/atmospheric_background.dart';

class ContactSelectView extends ConsumerStatefulWidget {
  const ContactSelectView({super.key});

  @override
  ConsumerState<ContactSelectView> createState() => _ContactSelectViewState();
}

class _ContactSelectViewState extends ConsumerState<ContactSelectView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreatingChat = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startDirectChatWithUser(ChatParticipantUser user) async {
    if (_isCreatingChat) return;
    setState(() => _isCreatingChat = true);

    try {
      await ChatNavigationHelper.startOrOpenDirectChat(
        context,
        ref,
        targetUserId: user.id,
        targetUserName: user.fullName,
        targetUserAvatar: user.avatarUrl,
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(campusUsersProvider(_searchQuery));
    final theme = Theme.of(context);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CampusAppBar(
          leading: CampusBackButton(),
          title: 'New Conversation',
        ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people by name, department, role...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Content List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Option to create a group
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => context.push('/chat/create-group'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.group_add, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Start a group chat with classmates or club members'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Available Campus Members',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                usersAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.person_search_outlined, size: 56, color: theme.colorScheme.outline),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No campus members matching "$_searchQuery"'
                                    : 'No new members available to message.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          onTap: () => _startDirectChatWithUser(user),
                          leading: Stack(
                            children: [
                              CampusAvatar(
                                imageUrl: user.avatarUrl,
                                name: user.fullName,
                                radius: 22,
                                onTap: () => context.push('/profile/${user.id}'),
                              ),
                              if (user.isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.displayUsername,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            user.departmentName != null && user.departmentName!.isNotEmpty
                                ? '${user.role} • ${user.departmentName}'
                                : '${user.role} • ${user.email}',
                            style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_outlined, size: 18, color: theme.colorScheme.primary),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading campus contacts: $err'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
