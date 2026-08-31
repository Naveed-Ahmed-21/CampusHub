import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';

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
      final repo = ref.read(chatRepositoryProvider);
      final room = await repo.getOrCreateDirectChat(user.id);
      ref.invalidate(userChatRoomsProvider);
      if (mounted) {
        context.pushReplacement('/chat/room/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(campusUsersProvider(_searchQuery));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Conversation'),
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
                              GestureDetector(
                                onTap: () => context.push('/profile/${user.id}'),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(ApiEndpoints.resolveUrl(user.avatarUrl!))
                                      : null,
                                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                      ? Text(
                                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        )
                                      : null,
                                ),
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
    );
  }
}
