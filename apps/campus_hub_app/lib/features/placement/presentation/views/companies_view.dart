import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_dialog.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CompaniesView extends ConsumerStatefulWidget {
  const CompaniesView({super.key});

  @override
  ConsumerState<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends ConsumerState<CompaniesView> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddCompanyDialog() {
    final nameCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    List<CompanyLookupResult> suggestions = [];
    bool isSearching = false;
    String? detectedLogo;
    String? detectedCover;
    String? detectedIndustry;
    String? detectedAbout;
    String? detectedLinkedin;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CampusDialog(
          title: 'Add Recruiting Company',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampusTextField(
                  controller: nameCtrl,
                  label: 'Company Name *',
                  prefixIcon: Icons.business,
                  hint: 'e.g. Google, Zoho, Microsoft, Infosys',
                  onChanged: (val) async {
                    if (val.trim().length < 2) {
                      setDialogState(() {
                        suggestions = [];
                        isSearching = false;
                      });
                      return;
                    }
                    setDialogState(() => isSearching = true);
                    try {
                      final repo = ref.read(placementRepositoryProvider);
                      final res = await repo.lookupCompanies(val.trim());
                      if (ctx.mounted) {
                        setDialogState(() {
                          suggestions = res;
                          isSearching = false;
                        });
                      }
                    } catch (_) {
                      if (ctx.mounted) setDialogState(() => isSearching = false);
                    }
                  },
                ),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                if (suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: suggestions.take(3).map((s) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: s.logoUrl != null ? NetworkImage(s.logoUrl!) : null,
                            child: s.logoUrl == null ? Text(s.name[0]) : null,
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(s.industry ?? s.domain ?? '', style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            setDialogState(() {
                              nameCtrl.text = s.name;
                              websiteCtrl.text = s.website ?? '';
                              detectedLogo = s.logoUrl;
                              detectedCover = s.coverImageUrl;
                              detectedIndustry = s.industry;
                              detectedAbout = s.about;
                              detectedLinkedin = s.linkedinUrl;
                              suggestions = [];
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                if (detectedLogo != null || detectedCover != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (detectedLogo != null)
                          CircleAvatar(radius: 14, backgroundImage: NetworkImage(detectedLogo!)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Logo & Office building auto-detected for ${nameCtrl.text}!',
                            style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CampusTextField(
                  controller: websiteCtrl,
                  label: 'Careers / Website URL',
                  prefixIcon: Icons.language,
                  hint: 'https://careers.company.com',
                ),
              ],
            ),
          ),
          actions: [
            CampusButton(
              label: 'Cancel',
              type: CampusButtonType.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            CampusButton(
              label: 'Add Company',
              type: CampusButtonType.primary,
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  final repo = ref.read(placementRepositoryProvider);
                  await repo.createCompany(
                    name: nameCtrl.text.trim(),
                    website: websiteCtrl.text.trim().isNotEmpty ? websiteCtrl.text.trim() : null,
                    logoUrl: detectedLogo,
                    coverImageUrl: detectedCover,
                    industry: detectedIndustry,
                    about: detectedAbout,
                    linkedinUrl: detectedLinkedin,
                  );
                  ref.invalidate(placementCompaniesProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Company added successfully with logo & profile!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final isOfficer = user?.isPlacementOfficer == true || user?.isAdmin == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final companiesAsync = ref.watch(placementCompaniesProvider);

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
                            'Recruiting Partners',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Companies partnering with GCEE Placement Cell',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOfficer)
                      IconButton(
                        icon: const Icon(Icons.add_business_outlined),
                        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        tooltip: 'Add Company',
                        onPressed: _showAddCompanyDialog,
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
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      hintText: 'Search companies...',
                      hintStyle: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Filter Pills (Image 07)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: ['ALL', 'ACTIVE', 'PAST'].map((pill) {
                    final isSelected = _selectedFilter == pill;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(pill == 'ALL' ? 'All Companies' : (pill == 'ACTIVE' ? 'Active' : 'Past Recruiters')),
                        selectedColor: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected
                              ? (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                              : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = pill);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Companies List
              Expanded(
                child: companiesAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load companies',
                    onRetry: () => ref.refresh(placementCompaniesProvider),
                  ),
                  data: (companies) {
                    final filtered = companies.where((c) {
                      if (_selectedFilter == 'ACTIVE' && c.drivesCount == 0) return false;
                      if (_selectedFilter == 'PAST' && c.drivesCount > 0) return false;
                      if (_searchQuery.isEmpty) return true;
                      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Companies Found',
                        description: _searchQuery.isEmpty
                            ? 'No companies registered yet. Add a partner company to get started.'
                            : 'No companies match "$_searchQuery".',
                        icon: Icons.business_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(placementCompaniesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final company = filtered[index];
                          return CampusGlassCard(
                            intensity: GlassIntensity.medium,
                            onTap: () => context.push('/placement/companies/${company.id}'),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: company.logoUrl != null
                                      ? Image.network(
                                          company.logoUrl!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        company.name,
                                        style: AppTypography.captionMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${company.drivesCount} Drives',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          if (company.industry != null) ...[
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                company.industry!,
                                                style: AppTypography.micro.copyWith(
                                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14),
                              ],
                            ),
                          );
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
      floatingActionButton: isOfficer
          ? FloatingActionButton.extended(
              onPressed: _showAddCompanyDialog,
              backgroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_business),
              label: const Text('Add Company', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

