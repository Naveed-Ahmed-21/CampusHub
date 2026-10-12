import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../controllers/auth_controller.dart';

class SetupPasswordView extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? token;

  const SetupPasswordView({
    super.key,
    this.initialEmail,
    this.token,
  });

  @override
  ConsumerState<SetupPasswordView> createState() => _SetupPasswordViewState();
}

class _SetupPasswordViewState extends ConsumerState<SetupPasswordView> {
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _sentEmail;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    if (widget.token != null && widget.token!.isNotEmpty) {
      _otpVerified = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  Color _getStrengthColor(int score) {
    if (score <= 1) return AppColors.error;
    if (score == 2) return AppColors.warning;
    if (score == 3) return Colors.amber;
    return AppColors.success;
  }

  String _getStrengthLabel(int score) {
    if (score == 0) return 'Enter a password';
    if (score == 1) return 'Very Weak';
    if (score == 2) return 'Weak';
    if (score == 3) return 'Moderate';
    return 'Strong';
  }

  Future<void> _onSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid campus email address to receive OTP.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final res = await ref.read(authControllerProvider.notifier).sendFirstLoginOtp(email);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        if (res != null) {
          _otpSent = true;
          _sentEmail = email;
          final previewOtp = res['previewOtp'];
          if (previewOtp != null) {
            _otpController.text = previewOtp;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res?['message'] ??
                  'Verification code dispatched to $email. Please check your inbox.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit OTP code sent to your email.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final res = await ref
          .read(authControllerProvider.notifier)
          .verifyFirstLoginOtp(email: email, otp: otp);

      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _otpVerified = res?['verified'] == true;
      });

      if (_otpVerified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! You may now set your password.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onSetupPassword() async {
    if (!_otpVerified && (widget.token == null || widget.token!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email address using the OTP code first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final otp = _otpController.text.trim();

      final success = await ref.read(authControllerProvider.notifier).setupPassword(
            email: email,
            newPassword: password,
            token: widget.token,
            otp: otp.isNotEmpty ? otp : null,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password configured successfully! Welcome to CampusHub.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        final error = ref.read(authControllerProvider).asError?.error;
        final errorMsg = error != null
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Password setup failed. Please try again.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CampusAppBar(
        title: 'Account Activation',
        subtitle: 'Government College of Engineering, Erode',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(context, isLoading),
            desktop: _buildDesktopLayout(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final password = _passwordController.text;
    final strength = _calculateStrength(password);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                    .withValues(alpha: isDark ? 0.2 : 0.1),
                border: Border.all(
                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                      .withValues(alpha: isDark ? 0.35 : 0.2),
                ),
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 28,
                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Institutional Account Activation',
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Verify your institutional email and set up your permanent login credentials.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Magic Link Notice if arriving via email link
          if (widget.token != null && widget.token!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.success, size: 22),
                  SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      'Email verified via activation link! Please set your new account password below.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],

          // Field 1: Email Address
          CampusTextField(
            controller: _emailController,
            label: 'Institutional Campus Email Address',
            hint: 'name@gcee.ac.in',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email address is required';
              if (!val.contains('@')) return 'Enter a valid institutional email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s12),

          // Action 1: Send Verification Email / Link
          if (widget.token == null || widget.token!.isEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: CampusButton.secondary(
                height: 40,
                icon: _isSendingOtp
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_otpSent ? Icons.refresh : Icons.send_rounded, size: 16),
                label: _otpSent
                    ? 'Resend Verification Code'
                    : 'Send Verification Code & Magic Link to Email',
                onPressed: _isSendingOtp ? null : _onSendOtp,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],

          // Banner when OTP is sent
          if (_otpSent && !_otpVerified) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verification code sent to $_sentEmail',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A 6-digit verification code has been dispatched to your institutional email. Please check your inbox and enter the code below.',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // OTP Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CampusTextField(
                    controller: _otpController,
                    label: '6-Digit Email Verification Code (OTP)',
                    hint: '123456',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (!_otpVerified && (val == null || val.trim().isEmpty)) {
                        return 'Enter verification code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                CampusButton.primary(
                  height: 48,
                  label: 'Verify',
                  isLoading: _isVerifyingOtp,
                  onPressed: _isVerifyingOtp ? null : _onVerifyOtp,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
          ],

          if (_otpVerified) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Email verified successfully!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],

          // Password Field
          CampusTextField(
            controller: _passwordController,
            label: 'New Account Password (Min 8 Characters)',
            hint: 'Choose a strong password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: secondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Password is required';
              if (val.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s8),

          // Strength indicator
          if (password.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength / 4,
                      backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(_getStrengthColor(strength)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getStrengthLabel(strength),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStrengthColor(strength),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
          ],

          // Confirm Password Field
          CampusTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Account Password',
            hint: 'Re-enter your password',
            obscureText: _obscureConfirmPassword,
            prefixIcon: Icons.lock_reset_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: secondary,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s24),

          CampusButton.primary(
            label: 'Verify OTP & Activate Account',
            isLoading: isLoading,
            onPressed: _onSetupPassword,
          ),
          const SizedBox(height: AppSpacing.s16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already activated your account?',
                style: AppTypography.body.copyWith(color: secondary, fontSize: 13),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Sign In',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: CampusGlassCard(
          intensity: GlassIntensity.strong,
          borderRadius: AppRadius.br24,
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: _buildForm(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: CampusGlassCard(
            intensity: GlassIntensity.strong,
            borderRadius: AppRadius.br24,
            padding: const EdgeInsets.all(AppSpacing.s32),
            child: _buildForm(context, isLoading),
          ),
        ),
      ),
    );
  }
}
