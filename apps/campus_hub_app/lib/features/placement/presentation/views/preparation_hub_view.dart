import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';

import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/services/campus_download_service.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class PreparationHubView extends ConsumerStatefulWidget {
  const PreparationHubView({super.key});

  @override
  ConsumerState<PreparationHubView> createState() => _PreparationHubViewState();
}

class _PreparationHubViewState extends ConsumerState<PreparationHubView> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'APTITUDE',
    'TECHNICAL',
    'HR',
    'COMPANY_SPECIFIC',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddResourceDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    String category = 'TECHNICAL';
    String resourceType = 'PDF';
    bool isFileUpload = true;
    SelectedMediaFile? pickedFile;
    bool isUploading = false;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Upload Preparation Resource',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CampusTextField(
                    controller: titleCtrl,
                    label: 'Resource Title *',
                    prefixIcon: Icons.title,
                    hint: 'e.g. DSA Cheat Sheet, Aptitude Formulas',
                  ),
                  const SizedBox(height: 12),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    key: ValueKey(category),
                    initialValue: category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TECHNICAL',
                        child: Text('Technical & Coding', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'APTITUDE',
                        child: Text('Aptitude & Quantitative', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'HR',
                        child: Text('HR & Behavioral Interview', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'COMPANY_SPECIFIC',
                        child: Text('Company-Specific Questions', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Format Dropdown
                  DropdownButtonFormField<String>(
                    key: ValueKey(resourceType),
                    initialValue: resourceType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Format *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PDF', child: Text('PDF Document', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'NOTES', child: Text('Notes / Cheatsheet', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'VIDEO', child: Text('Video Lecture', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'YOUTUBE_PLAYLIST', child: Text('YouTube / External Playlist', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'MOCK_TEST', child: Text('Mock Test / Quiz', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => resourceType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  // Resource Source Toggle
                  Row(
                    children: [
                      const Text('Source:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('File Upload'),
                        selected: isFileUpload,
                        onSelected: (val) => setDialogState(() => isFileUpload = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Web Link'),
                        selected: !isFileUpload,
                        onSelected: (val) => setDialogState(() => isFileUpload = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isFileUpload) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final files = await MediaPickerService.pickDocuments(
                          allowMultiple: false,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'zip'],
                        );
                        if (files.isNotEmpty) {
                          setDialogState(() {
                            pickedFile = files.first;
                            if (titleCtrl.text.trim().isEmpty) {
                              titleCtrl.text = pickedFile!.name.split('.').first;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pickedFile != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pickedFile != null ? pickedFile!.name : 'Select PDF / Document to upload',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkText : AppColors.primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pickedFile != null
                                        ? '${pickedFile!.formattedSize} • Ready to upload'
                                        : 'Supports PDF, PPT, Word, Text notes',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: null,
                              child: Text(pickedFile != null ? 'Change' : 'Browse'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    CampusTextField(
                      controller: urlCtrl,
                      label: 'Resource URL (Drive/PDF/YouTube/Link) *',
                      prefixIcon: Icons.link,
                      hint: 'https://...',
                    ),
                  ],
                  const SizedBox(height: 12),
                  CampusTextField(
                    controller: tagsCtrl,
                    label: 'Tags (comma separated)',
                    prefixIcon: Icons.tag,
                    hint: 'Arrays, Trees, Percentages, Zoho',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Brief Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                if (!isFileUpload && urlCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter an external resource URL'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                setDialogState(() => isUploading = true);
                                final nav = Navigator.of(ctx);
                                try {
                                  String? uploadedFileUrl;
                                  if (isFileUpload && pickedFile != null) {
                                    final uploadResult = await ref
                                        .read(mediaUploadServiceProvider)
                                        .uploadSelectedFile(pickedFile!);
                                    uploadedFileUrl = uploadResult.url;
                                  }

                                  final repo = ref.read(placementRepositoryProvider);
                                  final rawTags = tagsCtrl.text
                                      .split(',')
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();

                                  await repo.createResource(
                                    title: title,
                                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                                    category: category,
                                    resourceType: resourceType,
                                    fileUrl: uploadedFileUrl,
                                    externalUrl: urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                                    tags: rawTags,
                                  );

                                  ref.invalidate(placementResourcesProvider(category));
                                  ref.invalidate(placementResourcesProvider(_selectedCategory));
                                  ref.invalidate(placementResourcesProvider('ALL'));
                                  ref.invalidate(placementResourcesProvider(null));
                                  if (mounted) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                    nav.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Resource uploaded to Preparation Hub!'), backgroundColor: AppColors.success),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isUploading = false);
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
                                    );
                                  }
                                }
                              },
                        child: isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Upload Resource'),
                      ),
                    ],
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
    final user = ref.watch(authControllerProvider).asData?.value;
    final canUpload = user?.isPlacementOfficer == true || user?.isAdmin == true || user?.isFaculty == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resourcesAsync = ref.watch(placementResourcesProvider(_selectedCategory));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CampusBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparation Hub',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Aptitude, Tech DSA, HR, and Company Roadmaps',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canUpload)
                      IconButton(
                        icon: const Icon(Icons.upload_file_outlined),
                        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        tooltip: 'Upload Resource',
                        onPressed: _showAddResourceDialog,
                      ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                      hintText: 'Search notes, algorithms, playlists, formulas...',
                      hintStyle: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Categories Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          cat == 'ALL' ? 'All Resources' : cat.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.primaryText),
                          ),
                        ),
                        selectedColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Resources List
              Expanded(
                child: resourcesAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load preparation resources',
                    onRetry: () => ref.refresh(placementResourcesProvider(_selectedCategory)),
                  ),
                  data: (resources) {
                    final filtered = resources.where((r) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      return r.title.toLowerCase().contains(q) ||
                          (r.description?.toLowerCase().contains(q) ?? false) ||
                          r.tags.any((t) => t.toLowerCase().contains(q));
                    }).toList();

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => ref.refresh(placementResourcesProvider(_selectedCategory).future),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: CampusEmptyState(
                                  title: 'No Preparation Materials',
                                  description: _searchQuery.isEmpty
                                      ? 'No resources in this category yet. Swipe down to refresh.'
                                      : 'No resources match "$_searchQuery".',
                                  icon: Icons.menu_book_outlined,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(placementResourcesProvider(_selectedCategory).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final res = filtered[index];
                          return _buildResourceCard(context, res, isDark);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: _showAddResourceDialog,
              backgroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Resource', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildResourceCard(BuildContext context, PlacementResourceModel res, bool isDark) {
    IconData iconData;
    if (res.resourceType == 'VIDEO' || res.resourceType == 'YOUTUBE_PLAYLIST') {
      iconData = Icons.play_circle_outline;
    } else if (res.resourceType == 'PDF') {
      iconData = Icons.picture_as_pdf_outlined;
    } else if (res.resourceType == 'MOCK_TEST') {
      iconData = Icons.quiz_outlined;
    } else {
      iconData = Icons.description_outlined;
    }

    final hasUrl = (res.externalUrl != null && res.externalUrl!.isNotEmpty) ||
        (res.fileUrl != null && res.fileUrl!.isNotEmpty);

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      onTap: () => context.push('/placement/resources/${res.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.title,
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${res.category.replaceAll('_', ' ')} • ${res.resourceType}',
                      style: AppTypography.micro.copyWith(
                        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (res.description != null && res.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              res.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (res.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: res.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$tag', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 14, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(
                '${res.viewsCount} views',
                style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
              ),
              const Spacer(),
              if (res.fileUrl != null && res.fileUrl!.trim().isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20, color: Colors.blue),
                  tooltip: 'Download Resource',
                  onPressed: () {
                    final ext = res.resourceType == 'PDF' ? 'pdf' : (res.resourceType == 'VIDEO' ? 'mp4' : 'bin');
                    final fileName = '${res.title.replaceAll(RegExp(r'\s+'), '_')}.$ext';
                    CampusDownloadService.downloadResource(
                      context: context,
                      fileUrl: res.fileUrl!,
                      fileName: fileName,
                      subFolder: 'Placement_Preparation',
                    );
                  },
                ),
              if (hasUrl)
                TextButton.icon(
                  onPressed: () {
                    final target = res.externalUrl ?? res.fileUrl;
                    if (target != null) {
                      launchUrlString(target, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

