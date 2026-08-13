import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';

class CreateGroupView extends ConsumerStatefulWidget {
  const CreateGroupView({super.key});

  @override
  ConsumerState<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends ConsumerState<CreateGroupView> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<ChatParticipantUser> _selectedUsers = [];
  String _searchQuery = '';
  int _currentStep = 0; // 0: Select Members, 1: Group Details
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectUser(ChatParticipantUser user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      final memberIds = _selectedUsers.map((u) => u.id).toList();
      final room = await repo.createGroupChat(name: name, memberIds: memberIds);

      ref.invalidate(userChatRoomsProvider);

      if (mounted) {
        context.pushReplacement('/chat/room/${room.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$name" created!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(campusUsersProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Select Group Members' : 'New Group Info'),
      ),
      floatingActionButton: _currentStep == 0
          ? FloatingActionButton.extended(
              onPressed: _selectedUsers.isEmpty
                  ? null
                  : () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Next (${_selectedUsers.length})'),
            )
          : null,
      body: _currentStep == 0
          ? Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),

                // Selected members chip bar
                if (_selectedUsers.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _selectedUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            avatar: CircleAvatar(
                              child: Text(user.firstName[0].toUpperCase()),
                            ),
                            label: Text(user.firstName),
                            onDeleted: () => _toggleSelectUser(user),
                          ),
                        );
                      },
                    ),
                  ),

                const Divider(height: 1),

                Expanded(
                  child: usersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(child: Text('No contacts found'));
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelected = _selectedUsers.any((u) => u.id == user.id);

                          return ListTile(
                            onTap: () => _toggleSelectUser(user),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(user.email),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelectUser(user),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error loading contacts: $err')),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.groups, size: 48, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g. AI Research Group',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Members: ${_selectedUsers.map((u) => u.fullName).join(", ")}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 0),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createGroup,
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Create Group'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
