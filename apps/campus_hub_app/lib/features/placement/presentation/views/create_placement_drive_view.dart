import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

class CreatePlacementDriveView extends ConsumerStatefulWidget {
  const CreatePlacementDriveView({super.key});

  @override
  ConsumerState<CreatePlacementDriveView> createState() => _CreatePlacementDriveViewState();
}

class _CreatePlacementDriveViewState extends ConsumerState<CreatePlacementDriveView> {
  final _formKey = GlobalKey<FormState>();

  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _ctcCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _cgpaCtrl = TextEditingController(text: '6.5');
  final _backlogsCtrl = TextEditingController(text: '0');
  final _descriptionCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String _employmentType = 'FULL_TIME';
  String _workMode = 'ON_SITE';
  int _targetYear = 4;
  DateTime _deadline = DateTime.now().add(const Duration(days: 14));
  DateTime? _driveDate = DateTime.now().add(const Duration(days: 21));

  final List<String> _availableDepts = ['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL', 'AUTO', 'CSE (DS)'];
  final Set<String> _selectedDepts = {'CSE', 'IT', 'ECE', 'AUTO'};

  bool _isSubmitting = false;

  // Online Company Search & Auto-Detection
  Timer? _debounceTimer;
  List<CompanyLookupResult> _companySuggestions = [];
  bool _isSearchingCompanies = false;
  bool _showSuggestions = false;
  String? _bannerUrl;
  String? _companyLogo;
  String? _companyIndustry;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _companyCtrl.dispose();
    _roleCtrl.dispose();
    _ctcCtrl.dispose();
    _locationCtrl.dispose();
    _cgpaCtrl.dispose();
    _backlogsCtrl.dispose();
    _descriptionCtrl.dispose();
    _skillsCtrl.dispose();
    _venueCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _onCompanySearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _companySuggestions = [];
        _showSuggestions = false;
        _isSearchingCompanies = false;
      });
      return;
    }

    setState(() => _isSearchingCompanies = true);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final repo = ref.read(placementRepositoryProvider);
        final results = await repo.lookupCompanies(trimmed);
        if (mounted) {
          setState(() {
            _companySuggestions = results;
            _showSuggestions = results.isNotEmpty;
            _isSearchingCompanies = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearchingCompanies = false);
      }
    });
  }

  void _selectCompany(CompanyLookupResult result) {
    setState(() {
      _companyCtrl.text = result.name;
      _bannerUrl = result.coverImageUrl;
      _companyLogo = result.logoUrl;
      _companyIndustry = result.industry;
      _websiteCtrl.text = result.website ?? '';
      if (_descriptionCtrl.text.isEmpty && result.about != null) {
        _descriptionCtrl.text = result.about!;
      }
      _showSuggestions = false;
      _companySuggestions = [];
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDeadline) async {
    final initialDate = isDeadline ? _deadline : (_driveDate ?? DateTime.now().add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDeadline) {
          _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        } else {
          _driveDate = DateTime(picked.year, picked.month, picked.day, 9, 0, 0);
        }
      });
    }
  }

  Future<void> _submitDrive() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyCtrl.text.trim().isEmpty || _roleCtrl.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(placementRepositoryProvider);
      final rawSkills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await repo.createDrive(
        companyName: _companyCtrl.text.trim(),
        roleTitle: _roleCtrl.text.trim(),
        packageCtc: _ctcCtrl.text.trim().isNotEmpty ? _ctcCtrl.text.trim() : null,
        location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
        minCgpa: double.tryParse(_cgpaCtrl.text.trim()) ?? 0.0,
        allowedDepartments: _selectedDepts.toList(),
        maxBacklogs: int.tryParse(_backlogsCtrl.text.trim()) ?? 0,
        jobDescription: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
        targetYear: _targetYear,
        employmentType: _employmentType,
        workMode: _workMode,
        requiredSkills: rawSkills,
        deadline: _deadline.toUtc().toIso8601String(),
        driveDate: _driveDate?.toUtc().toIso8601String(),
        venueOrLink: _venueCtrl.text.trim().isNotEmpty ? _venueCtrl.text.trim() : null,
        bannerUrl: _bannerUrl,
      );

      // Invalidate placement providers
      ref.invalidate(placementDrivesProvider);
      ref.invalidate(placementDrivesByStatusProvider);
      ref.invalidate(officerDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive published successfully! Dedicated chat room created and eligible students notified.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            'Post Placement Drive',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Automates group chat room and student eligibility scoping',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CampusGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company & Role Details',
                              style: AppTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CampusTextField(
                              controller: _companyCtrl,
                              label: 'Company Name *',
                              prefixIcon: Icons.business,
                              hint: 'Type company name (e.g. Google, TCS, Infosys, Zoho)',
                              onChanged: _onCompanySearchChanged,
                              suffixIcon: _isSearchingCompanies
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_companyCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _companyCtrl.clear();
                                              _bannerUrl = null;
                                              _companyLogo = null;
                                              _companyIndustry = null;
                                              _companySuggestions = [];
                                              _showSuggestions = false;
                                            });
                                          },
                                        )
                                      : null),
                            ),
                            if (_showSuggestions && _companySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Text(
                                        'Online Database Matches (tap to auto-fill)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    ..._companySuggestions.map((result) {
                                      return ListTile(
                                        dense: true,
                                        leading: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: result.logoUrl != null
                                              ? Image.network(
                                                  result.logoUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) => Center(
                                                    child: Text(
                                                      result.name.isNotEmpty ? result.name[0] : 'C',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    result.name.isNotEmpty ? result.name[0] : 'C',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                        ),
                                        title: Text(
                                          result.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          result.industry ?? result.domain ?? 'Corporate Recruiter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                          ),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                        onTap: () => _selectCompany(result),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            if (_bannerUrl != null || _companyLogo != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          height: 110,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            image: _bannerUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(_bannerUrl!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Container(
                                          height: 110,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.2),
                                                Colors.black.withValues(alpha: 0.65),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _bannerUrl = null;
                                                _companyLogo = null;
                                                _companyIndustry = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.close, size: 14, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Reset Image',
                                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          left: 12,
                                          right: 12,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 46,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.2),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: _companyLogo != null
                                                    ? Image.network(
                                                        _companyLogo!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (_, __, ___) => Center(
                                                          child: Text(
                                                            _companyCtrl.text.isNotEmpty ? _companyCtrl.text[0].toUpperCase() : 'C',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                                                          ),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Text(
                                                          _companyCtrl.text.isNotEmpty ? _companyCtrl.text[0].toUpperCase() : 'C',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _companyCtrl.text,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (_companyIndustry != null)
                                                      Text(
                                                        _companyIndustry!,
                                                        style: TextStyle(
                                                          color: Colors.white.withValues(alpha: 0.9),
                                                          fontSize: 11,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Auto-detected company logo & modern headquarters cover photo',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            CampusTextField(
                              controller: _roleCtrl,
                              label: 'Role Title *',
                              prefixIcon: Icons.work_outline,
                              hint: 'e.g. Graduate Software Engineer',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CampusTextField(
                                    controller: _ctcCtrl,
                                    label: 'Package CTC',
                                    prefixIcon: Icons.payments_outlined,
                                    hint: 'e.g. 10 - 14 LPA',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CampusTextField(
                                    controller: _locationCtrl,
                                    label: 'Job Location',
                                    prefixIcon: Icons.location_on_outlined,
                                    hint: 'e.g. Bangalore / Remote',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 440;
                                final typeField = DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _employmentType,
                                  decoration: InputDecoration(
                                    labelText: 'Type',
                                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'FULL_TIME',
                                      child: Text('Full Time', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'INTERNSHIP',
                                      child: Text('Internship', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'INTERN_TO_FULL_TIME',
                                      child: Text('Intern to Full Time', overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _employmentType = val);
                                  },
                                );

                                final modeField = DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _workMode,
                                  decoration: InputDecoration(
                                    labelText: 'Mode',
                                    prefixIcon: const Icon(Icons.apartment_outlined, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'ON_SITE',
                                      child: Text('On-Site', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'HYBRID',
                                      child: Text('Hybrid', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'REMOTE',
                                      child: Text('Remote', overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _workMode = val);
                                  },
                                );

                                if (isCompact) {
                                  return Column(
                                    children: [
                                      typeField,
                                      const SizedBox(height: 12),
                                      modeField,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: typeField),
                                    const SizedBox(width: 12),
                                    Expanded(child: modeField),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Eligibility & Target Audience
                      CampusGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eligibility & Target Audience',
                              style: AppTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CampusTextField(
                                    controller: _cgpaCtrl,
                                    keyboardType: TextInputType.number,
                                    label: 'Min CGPA Cutoff',
                                    prefixIcon: Icons.grade_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CampusTextField(
                                    controller: _backlogsCtrl,
                                    keyboardType: TextInputType.number,
                                    label: 'Max Backlogs',
                                    prefixIcon: Icons.warning_amber_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Target Academic Year',
                              style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [3, 4].map((year) {
                                final isSelected = _targetYear == year;
                                final label = year == 3 ? '3rd Year (Pre-Final)' : '4th Year (Final Year)';
                                return ChoiceChip(
                                  selected: isSelected,
                                  label: Text(label),
                                  onSelected: (val) {
                                    if (val) setState(() => _targetYear = year);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Allowed Branches',
                              style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableDepts.map((dept) {
                                final isSelected = _selectedDepts.contains(dept);
                                final label = dept == 'AUTO'
                                    ? 'Auto (Automobile)'
                                    : (dept == 'CSE (DS)' ? 'CSE (Data Science)' : dept);
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(label),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        _selectedDepts.add(dept);
                                      } else {
                                        _selectedDepts.remove(dept);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Schedule & Venue
                      CampusGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule & Venue',
                              style: AppTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              title: const Text('Application Deadline'),
                              subtitle: Text(_deadline.toLocal().toString().split(' ')[0]),
                              leading: const Icon(Icons.event_outlined),
                              trailing: TextButton(
                                onPressed: () => _selectDate(context, true),
                                child: const Text('Change'),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Drive / Interview Date'),
                              subtitle: Text(_driveDate?.toLocal().toString().split(' ')[0] ?? 'Not scheduled yet'),
                              leading: const Icon(Icons.calendar_month_outlined),
                              trailing: TextButton(
                                onPressed: () => _selectDate(context, false),
                                child: const Text('Change'),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 8),
                            CampusTextField(
                              controller: _venueCtrl,
                              label: 'Venue or Virtual Meeting Link',
                              prefixIcon: Icons.location_city_outlined,
                              hint: 'e.g. Auditorium / Google Meet link',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description & Skills
                      CampusGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description & Skills',
                              style: AppTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CampusTextField(
                              controller: _skillsCtrl,
                              label: 'Required Skills (comma separated)',
                              prefixIcon: Icons.psychology_outlined,
                              hint: 'Java, DSA, SQL, System Design, Communication',
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descriptionCtrl,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Job Description & Instructions',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      CampusButton(
                        label: 'Publish Placement Drive',
                        icon: const Icon(Icons.rocket_launch_outlined),
                        type: CampusButtonType.primary,
                        isLoading: _isSubmitting,
                        onPressed: _submitDrive,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
