import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/atmospheric_background.dart';

class StudentOnboardingView extends ConsumerStatefulWidget {
  final int initialStep;
  const StudentOnboardingView({super.key, this.initialStep = 0});

  @override
  ConsumerState<StudentOnboardingView> createState() => _StudentOnboardingViewState();
}

class _StudentOnboardingViewState extends ConsumerState<StudentOnboardingView> {
  late int _currentStep;
  bool _isLoadingContext = true;
  bool _isSubmitting = false;

  // Onboarding context from server
  Map<String, dynamic>? _contextData;

  // Form Controllers - Step 1: Personal & Family
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _studentPhoneCtrl = TextEditingController();
  DateTime? _selectedDob;
  String _selectedBloodGroup = 'O+';
  final _fatherNameCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyRelationCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  // Form Controllers - Step 2: Academic
  final _rollNumberCtrl = TextEditingController();
  final _registrationNumberCtrl = TextEditingController();

  // Form Controllers - Step 3: Address & Education
  final _permAddressCtrl = TextEditingController();
  final _permCityCtrl = TextEditingController();
  final _permStateCtrl = TextEditingController();
  final _permPincodeCtrl = TextEditingController();
  bool _currentSameAsPerm = true;
  final _currAddressCtrl = TextEditingController();
  final _currCityCtrl = TextEditingController();
  final _currStateCtrl = TextEditingController();
  final _currPincodeCtrl = TextEditingController();
  final _tenthPercentageCtrl = TextEditingController();
  final _twelfthPercentageCtrl = TextEditingController();

  // Step 4: Review confirmation
  bool _declarationConfirmed = false;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _fetchOnboardingContext();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _studentPhoneCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherPhoneCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherPhoneCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyRelationCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _rollNumberCtrl.dispose();
    _registrationNumberCtrl.dispose();
    _permAddressCtrl.dispose();
    _permCityCtrl.dispose();
    _permStateCtrl.dispose();
    _permPincodeCtrl.dispose();
    _currAddressCtrl.dispose();
    _currCityCtrl.dispose();
    _currStateCtrl.dispose();
    _currPincodeCtrl.dispose();
    _tenthPercentageCtrl.dispose();
    _twelfthPercentageCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOnboardingContext() async {
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.get('/api/v1/profile/onboarding-context');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};

      setState(() {
        _contextData = data;
        _firstNameCtrl.text = data['firstName'] ?? '';
        _lastNameCtrl.text = data['lastName'] ?? '';
        _rollNumberCtrl.text = data['rollNumber'] ?? '';
        _registrationNumberCtrl.text = data['registrationNumber'] ?? '';
        _isLoadingContext = false;
      });
    } catch (_) {
      setState(() => _isLoadingContext = false);
    }
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String? _validatePhoneDistinctness() {
    final sPhone = _studentPhoneCtrl.text.trim();
    final fPhone = _fatherPhoneCtrl.text.trim();
    final mPhone = _motherPhoneCtrl.text.trim();

    if (sPhone.isNotEmpty && fPhone.isNotEmpty && sPhone == fPhone) {
      return 'Student mobile number cannot be identical to father mobile number.';
    }
    if (sPhone.isNotEmpty && mPhone.isNotEmpty && sPhone == mPhone) {
      return 'Student mobile number cannot be identical to mother mobile number.';
    }
    if (fPhone.isNotEmpty && mPhone.isNotEmpty && fPhone == mPhone) {
      return 'Father mobile number cannot be identical to mother mobile number.';
    }
    return null;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your Date of Birth.')),
        );
        return;
      }
      final distinctErr = _validatePhoneDistinctness();
      if (distinctErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(distinctErr), backgroundColor: Colors.red.shade700),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!(_step2Key.currentState?.validate() ?? false)) return;
    } else if (_currentStep == 2) {
      if (!(_step3Key.currentState?.validate() ?? false)) return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_declarationConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the institutional declaration before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioClientProvider);
      final payload = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _studentPhoneCtrl.text.trim(),
        'dob': _selectedDob?.toIso8601String(),
        'bloodGroup': _selectedBloodGroup,
        'fatherName': _fatherNameCtrl.text.trim(),
        'fatherPhone': _fatherPhoneCtrl.text.trim(),
        'motherName': _motherNameCtrl.text.trim(),
        'motherPhone': _motherPhoneCtrl.text.trim(),
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactRelation': _emergencyRelationCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        'permanentAddress': _permAddressCtrl.text.trim(),
        'permanentCity': _permCityCtrl.text.trim(),
        'permanentState': _permStateCtrl.text.trim(),
        'permanentPincode': _permPincodeCtrl.text.trim(),
        'currentAddress': _currentSameAsPerm ? _permAddressCtrl.text.trim() : _currAddressCtrl.text.trim(),
        'currentCity': _currentSameAsPerm ? _permCityCtrl.text.trim() : _currCityCtrl.text.trim(),
        'currentState': _currentSameAsPerm ? _permStateCtrl.text.trim() : _currStateCtrl.text.trim(),
        'currentPincode': _currentSameAsPerm ? _permPincodeCtrl.text.trim() : _currPincodeCtrl.text.trim(),
        'tenthPercentage': double.tryParse(_tenthPercentageCtrl.text.trim()) ?? 0.0,
        if (_twelfthPercentageCtrl.text.trim().isNotEmpty)
          'twelfthPercentage': double.tryParse(_twelfthPercentageCtrl.text.trim()),
        if (_rollNumberCtrl.text.trim().isNotEmpty) 'rollNumber': _rollNumberCtrl.text.trim(),
        if (_registrationNumberCtrl.text.trim().isNotEmpty)
          'registrationNumber': _registrationNumberCtrl.text.trim(),
      };

      await dio.post('/api/v1/profile/onboarding', data: payload);

      // Update AuthUser in local state so router immediately recognises active profile
      final currentUser = ref.read(authControllerProvider).asData?.value;
      if (currentUser != null) {
        ref.read(authControllerProvider.notifier).updateUser(
              currentUser.copyWith(
                isProfileCompleted: true,
                firstLoginCompleted: true,
                status: 'ACTIVE',
              ),
            );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding completed successfully! Welcome to CampusHub.'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/feed');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete onboarding: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingContext) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your academic record...'),
            ],
          ),
        ),
      );
    }

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          title: 'Student Onboarding',
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top Progress Bar
                  _buildProgressHeader(theme),
                  const SizedBox(height: 12),

                  // Form Step Content
                  Expanded(
                    child: Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: _buildCurrentStep(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Navigation Bar
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme) {
    final steps = ['Personal', 'Academic', 'Education', 'Review'];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isActive = idx == _currentStep;
        final isPassed = idx < _currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: idx == 0
                          ? Colors.transparent
                          : (isPassed || isActive ? theme.colorScheme.primary : Colors.grey.shade300),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isPassed
                        ? Colors.green
                        : (isActive ? theme.colorScheme.primary : Colors.grey.shade300),
                    child: isPassed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: idx == steps.length - 1
                          ? Colors.transparent
                          : (isPassed ? theme.colorScheme.primary : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? theme.colorScheme.primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal(theme);
      case 1:
        return _buildStep2Academic(theme);
      case 2:
        return _buildStep3AddressAndEducation(theme);
      case 3:
        return _buildStep4Review(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Personal(ThemeData theme) {
    final age = _calculateAge(_selectedDob);

    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Personal & Family Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Enter your identity details accurately as per your matriculation record.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          const Divider(height: 24),

          // Field 1: First Name (Placed one by one with full text label)
          CustomTextField(
            controller: _firstNameCtrl,
            label: 'First Name',
            prefixIcon: Icons.badge_outlined,
            validator: (val) => val == null || val.trim().isEmpty ? 'First name is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 2: Last Name (Placed one by one with full text label)
          CustomTextField(
            controller: _lastNameCtrl,
            label: 'Last Name',
            prefixIcon: Icons.badge_outlined,
            validator: (val) => val == null || val.trim().isEmpty ? 'Last name is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 3: Student Mobile Number (Placed one by one with full text label)
          CustomTextField(
            controller: _studentPhoneCtrl,
            label: 'Student Mobile Number (10 Digits)',
            prefixIcon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Student mobile number is required';
              if (val.trim().length < 10) return 'Enter at least 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Field 4: Date of Birth (Placed one by one with full text label & age indicator)
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDob ?? DateTime(2004, 1, 1),
                firstDate: DateTime(1980),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
              );
              if (picked != null) {
                setState(() => _selectedDob = picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of Birth (YYYY-MM-DD)',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: age != null
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: age >= 15 ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: age >= 15 ? Colors.green.shade400 : Colors.orange.shade400,
                          ),
                        ),
                        child: Text(
                          '$age Yrs Old',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: age >= 15 ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      )
                    : const Icon(Icons.arrow_drop_down),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                _selectedDob != null
                    ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
                    : 'Select Date of Birth',
                style: TextStyle(
                  color: _selectedDob != null ? theme.textTheme.bodyMedium?.color : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Field 5: Blood Group (Placed one by one with full text label)
          DropdownButtonFormField<String>(
            initialValue: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group (ABO & Rh Factor)',
              prefixIcon: Icon(Icons.water_drop_outlined),
              border: OutlineInputBorder(),
            ),
            items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedBloodGroup = val);
            },
          ),
          const SizedBox(height: 16),

          // Field 6: Father Full Name (Placed one by one with full text label)
          CustomTextField(
            controller: _fatherNameCtrl,
            label: 'Father Full Name',
            prefixIcon: Icons.person,
            validator: (val) => val == null || val.trim().isEmpty ? 'Father full name is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 7: Father Mobile Number (Placed one by one with full text label)
          CustomTextField(
            controller: _fatherPhoneCtrl,
            label: 'Father Mobile Number (10 Digits)',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Father mobile number is required';
              if (val.trim().length < 10) return 'Enter at least 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Field 8: Mother Full Name (Placed one by one with full text label)
          CustomTextField(
            controller: _motherNameCtrl,
            label: 'Mother Full Name',
            prefixIcon: Icons.person_3_outlined,
            validator: (val) => val == null || val.trim().isEmpty ? 'Mother full name is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 9: Mother Mobile Number (Placed one by one with full text label)
          CustomTextField(
            controller: _motherPhoneCtrl,
            label: 'Mother Mobile Number (10 Digits)',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Mother mobile number is required';
              if (val.trim().length < 10) return 'Enter at least 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Field 10: Emergency Contact Person Name (Placed one by one with full text label)
          CustomTextField(
            controller: _emergencyNameCtrl,
            label: 'Emergency Contact Person Name',
            prefixIcon: Icons.emergency,
            validator: (val) => val == null || val.trim().isEmpty ? 'Emergency contact name is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 11: Emergency Contact Relationship (Placed one by one with full text label)
          CustomTextField(
            controller: _emergencyRelationCtrl,
            label: 'Relationship to Student (e.g. Parent, Guardian, Sibling)',
            prefixIcon: Icons.group,
            validator: (val) => val == null || val.trim().isEmpty ? 'Relationship is required' : null,
          ),
          const SizedBox(height: 16),

          // Field 12: Emergency Contact Phone Number (Placed one by one with full text label)
          CustomTextField(
            controller: _emergencyPhoneCtrl,
            label: 'Emergency Contact Phone Number (10 Digits)',
            prefixIcon: Icons.phone_in_talk,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Emergency phone number is required';
              if (val.trim().length < 10) return 'Enter at least 10 digits';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Academic(ThemeData theme) {
    final dept = _contextData?['departmentName'] ?? 'Assigned Department';
    final prog = _contextData?['programName'] ?? 'Academic Program';
    final batch = _contextData?['batchName'] ?? '2023 - 2027';
    final section = _contextData?['section'] ?? 'A';

    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Academic Assignment Verification',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The institutional attributes below are assigned by campus administration and are locked for integrity.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const Divider(height: 24),

          // Locked Institutional Cards Grid
          Column(
            children: [
              _buildLockedInfoCard(theme, 'Assigned Department', dept, Icons.business),
              const SizedBox(height: 10),
              _buildLockedInfoCard(theme, 'Academic Program', prog, Icons.auto_stories),
              const SizedBox(height: 10),
              _buildLockedInfoCard(theme, 'Cohort / Batch', batch, Icons.group_work),
              const SizedBox(height: 10),
              _buildLockedInfoCard(theme, 'Assigned Section', 'Section $section', Icons.class_),
            ],
          ),
          const SizedBox(height: 24),

          // Student Identifiers (Editable if blank, placed one by one with full text labels)
          CustomTextField(
            controller: _rollNumberCtrl,
            label: 'Roll Number / Student Identification Number',
            prefixIcon: Icons.numbers,
            validator: (val) => val == null || val.trim().isEmpty ? 'Roll number is required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registrationNumberCtrl,
            label: 'Official University Registration / Enrolment Number',
            prefixIcon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 20),

          // Security Integrity Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Once onboarding is submitted, corrections to these academic attributes will require an official administrative change request with document verification.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedInfoCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStep3AddressAndEducation(ThemeData theme) {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Address & Prior Education',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),

          Text('Permanent Address', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _permAddressCtrl,
            label: 'Street Address',
            prefixIcon: Icons.location_on_outlined,
            validator: (val) => val == null || val.trim().isEmpty ? 'Address required' : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _permCityCtrl,
            label: 'Permanent City / District',
            prefixIcon: Icons.location_city,
            validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _permStateCtrl,
            label: 'Permanent State / Province',
            prefixIcon: Icons.map,
            validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _permPincodeCtrl,
            label: 'Permanent Postal Pincode / ZIP Code',
            prefixIcon: Icons.pin_drop,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.trim().isEmpty ? 'Pincode is required' : null,
          ),
          const SizedBox(height: 16),

          // Current Address Checkbox
          CheckboxListTile(
            title: const Text('Current address is same as permanent address'),
            value: _currentSameAsPerm,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _currentSameAsPerm = val ?? true),
          ),

          if (!_currentSameAsPerm) ...[
            const SizedBox(height: 8),
            CustomTextField(
              controller: _currAddressCtrl,
              label: 'Current Street Address',
              prefixIcon: Icons.map_outlined,
              validator: (val) => val == null || val.trim().isEmpty ? 'Current address required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _currCityCtrl,
              label: 'Current City / District',
              prefixIcon: Icons.location_city,
              validator: (val) => val == null || val.trim().isEmpty ? 'Current city required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _currStateCtrl,
              label: 'Current State / Province',
              prefixIcon: Icons.map,
              validator: (val) => val == null || val.trim().isEmpty ? 'Current state required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _currPincodeCtrl,
              label: 'Current Postal Pincode / ZIP Code',
              prefixIcon: Icons.pin_drop,
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.trim().isEmpty ? 'Current pincode required' : null,
            ),
          ],
          const SizedBox(height: 24),

          Text('Prior Academic Record', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _tenthPercentageCtrl,
            label: '10th Standard / Matriculation Aggregate Percentage (%)',
            prefixIcon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return '10th percentage is required';
              final n = double.tryParse(val.trim());
              if (n == null || n < 0 || n > 100) return '0 to 100';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _twelfthPercentageCtrl,
            label: '12th Standard / Higher Secondary / Diploma Percentage (%) [Optional]',
            prefixIcon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Review(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Review & Institutional Confirmation',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Verify your profile details before finalizing your official enrolment record.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
        const Divider(height: 24),

        _buildReviewCard(
          theme,
          title: 'Personal Information',
          icon: Icons.person,
          stepIndex: 0,
          details: {
            'Full Name': '${_firstNameCtrl.text} ${_lastNameCtrl.text}',
            'Student Mobile': _studentPhoneCtrl.text,
            'Date of Birth': _selectedDob?.toIso8601String().split('T').first ?? '--',
            'Age': '${_calculateAge(_selectedDob) ?? '--'} years',
            'Blood Group': _selectedBloodGroup,
          },
        ),
        const SizedBox(height: 12),

        _buildReviewCard(
          theme,
          title: 'Family & Emergency Contacts',
          icon: Icons.family_restroom,
          stepIndex: 0,
          details: {
            'Father': '${_fatherNameCtrl.text} (${_fatherPhoneCtrl.text})',
            'Mother': '${_motherNameCtrl.text} (${_motherPhoneCtrl.text})',
            'Emergency Contact': '${_emergencyNameCtrl.text} [${_emergencyRelationCtrl.text}] (${_emergencyPhoneCtrl.text})',
          },
        ),
        const SizedBox(height: 12),

        _buildReviewCard(
          theme,
          title: 'Academic Assignment',
          icon: Icons.school,
          stepIndex: 1,
          details: {
            'Department': _contextData?['departmentName'] ?? 'Computer Science',
            'Program': _contextData?['programName'] ?? 'B.Tech',
            'Roll Number': _rollNumberCtrl.text,
            'Registration No': _registrationNumberCtrl.text.isEmpty ? 'Pending' : _registrationNumberCtrl.text,
          },
        ),
        const SizedBox(height: 12),

        _buildReviewCard(
          theme,
          title: 'Address & Education',
          icon: Icons.home,
          stepIndex: 2,
          details: {
            'Permanent Address': '${_permAddressCtrl.text}, ${_permCityCtrl.text}, ${_permStateCtrl.text} - ${_permPincodeCtrl.text}',
            '10th Percentage': '${_tenthPercentageCtrl.text}%',
            if (_twelfthPercentageCtrl.text.isNotEmpty) '12th Percentage': '${_twelfthPercentageCtrl.text}%',
          },
        ),
        const SizedBox(height: 24),

        // Declaration Checkbox
        CheckboxListTile(
          value: _declarationConfirmed,
          onChanged: (val) => setState(() => _declarationConfirmed = val ?? false),
          title: const Text(
            'I confirm that the above details are authentic, match my official educational certificates, and comply with institutional policy.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Falsification of academic records or identity attributes constitutes a violation of the campus code of conduct.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required int stepIndex,
    required Map<String, String> details,
  }) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _currentStep = stepIndex),
                ),
              ],
            ),
            const Divider(height: 12),
            ...details.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(e.key, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Back'),
            onPressed: _prevStep,
          )
        else
          const SizedBox(width: 1),

        const SizedBox(width: 8),

        Flexible(
          child: _currentStep < 3
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  onPressed: _nextStep,
                )
              : ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text(
                    'Complete Onboarding',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _submitOnboarding,
                ),
        ),
      ],
    );
  }
}
