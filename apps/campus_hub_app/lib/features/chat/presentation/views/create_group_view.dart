import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
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
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  final List<ChatParticipantUser> _selectedUsers = [];
  SelectedMediaFile? _selectedGroupImage;
  String _searchQuery = '';
  int _currentStep = 0; // 0: Select Members, 1: Group Details
  bool _isPrivate = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo (Camera)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.pickImageFromCamera();
                  if (file != null && mounted) {
                    setState(() => _selectedGroupImage = file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choose Image (Gallery)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.pickImageFromGallery();
                  if (file != null && mounted) {
                    setState(() => _selectedGroupImage = file);
                  }
                },
              ),
              if (_selectedGroupImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedGroupImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedAvatarUrl;
      if (_selectedGroupImage != null) {
        final uploadService = ref.read(mediaUploadServiceProvider);
        final uploadResult = await uploadService.uploadSelectedFile(_selectedGroupImage!);
        uploadedAvatarUrl = uploadResult.url;
      }

      final repo = ref.read(chatRepositoryProvider);
      final memberIds = _selectedUsers.map((u) => u.id).toList();
      final room = await repo.createGroupChat(
        name: name,
        description: desc.isNotEmpty ? desc : null,
        avatarUrl: uploadedAvatarUrl,
        isPrivate: _isPrivate,
        memberIds: memberIds,
      );

      ref.invalidate(userChatRoomsProvider);
      ref.invalidate(publicGroupsProvider(null));

      if (mounted) {
        context.pushReplacement('/chat/room/${room.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isPrivate ? "Private" : "Public"} group "$name" created!'),
            backgroundColor: Colors.green,
          ),
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
        title: Text(_currentStep == 0 ? 'Select Group Members' : 'Create Group'),
      ),
      floatingActionButton: _currentStep == 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_forward),
              label: Text(_selectedUsers.isEmpty ? 'Skip & Configure' : 'Next (${_selectedUsers.length})'),
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
                              child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U'),
                            ),
                            label: Text(user.fullName),
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
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              user.displayUsername,
                              style: TextStyle(color: theme.colorScheme.primary, fontSize: 12.5),
                            ),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: _selectedGroupImage != null
                              ? (_selectedGroupImage!.bytes != null
                                  ? MemoryImage(_selectedGroupImage!.bytes!) as ImageProvider
                                  : (_selectedGroupImage!.path != null
                                      ? FileImage(File(_selectedGroupImage!.path!)) as ImageProvider
                                      : null))
                              : null,
                          child: _selectedGroupImage == null
                              ? Icon(
                                  _isPrivate ? Icons.lock_outline : Icons.groups,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              onPressed: _showImageSourcePicker,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showImageSourcePicker,
                      icon: const Icon(Icons.add_photo_alternate, size: 16),
                      label: Text(
                        _selectedGroupImage != null ? 'Change Group Image' : 'Add Group Image (Optional)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'e.g. Flutter Study Circle',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Group Description (Optional)',
                      hintText: 'What is this group about?',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Group Type',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: !_isPrivate ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: !_isPrivate ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _isPrivate = false),
                      leading: const Icon(Icons.public, color: Colors.blue),
                      title: const Text('Public Group', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Anyone on campus can discover and join this group freely.'),
                      trailing: Icon(
                        !_isPrivate ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: !_isPrivate ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isPrivate ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: _isPrivate ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _isPrivate = true),
                      leading: const Icon(Icons.lock, color: Colors.orange),
                      title: const Text('Private Group', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Only admins can add or invite members. Hidden from public discovery.'),
                      trailing: Icon(
                        _isPrivate ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _isPrivate ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedUsers.isNotEmpty)
                    Text(
                      'Initial Members (${_selectedUsers.length}): ${_selectedUsers.map((u) => u.fullName).join(", ")}',
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
                    ),
                  const SizedBox(height: 28),

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
                        child: FilledButton(
                          onPressed: _isLoading ? null : _createGroup,
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
