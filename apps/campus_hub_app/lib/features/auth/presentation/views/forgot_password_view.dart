import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_logo.dart';
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

enum ForgotPasswordStep {
  enterEmail,
  enterOtp,
  newPassword,
  success,
}

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _verifiedResetToken;

  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
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

  // --- Step 1: Send OTP to Email ---
  Future<void> _handleSendOtp() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      _startCountdown();
      setState(() {
        _currentStep = ForgotPasswordStep.enterOtp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // --- Step 2: Verify OTP Code ---
  Future<void> _handleVerifyOtp() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    try {
      final res = await ref.read(authControllerProvider.notifier).verifyForgotPasswordOtp(
            email: email,
            otp: otp,
          );
      final token = res?['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Failed to receive verified reset session token.');
      }
      _countdownTimer?.cancel();
      setState(() {
        _verifiedResetToken = token;
        _currentStep = ForgotPasswordStep.newPassword;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // --- Step 3: Set New Password ---
  Future<void> _handleResetPassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newPassword = _passwordController.text.trim();
    final token = _verifiedResetToken;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Reset verification token expired. Please start over.';
        _currentStep = ForgotPasswordStep.enterEmail;
      });
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: token,
            newPassword: newPassword,
          );
      setState(() {
        _currentStep = ForgotPasswordStep.success;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CampusAppBar(
        title: 'Institutional Password Recovery',
        subtitle: 'Government College of Engineering, Erode',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: CampusGlassCard(
          intensity: GlassIntensity.strong,
          borderRadius: AppRadius.br24,
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: _buildCurrentStep(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: CampusGlassCard(
            intensity: GlassIntensity.strong,
            borderRadius: AppRadius.br24,
            padding: const EdgeInsets.all(AppSpacing.s32),
            child: _buildCurrentStep(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0x3310243D) : Colors.white.withValues(alpha: 0.9),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const GceeLogo(
          size: 48,
        ),
      ),
    );
  }

  Widget _buildStepBadge(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: AppRadius.br12,
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: AppTypography.captionMedium.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppRadius.br12,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.captionMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case ForgotPasswordStep.enterEmail:
        return _buildEmailStep(context);
      case ForgotPasswordStep.enterOtp:
        return _buildOtpStep(context);
      case ForgotPasswordStep.newPassword:
        return _buildNewPasswordStep(context);
      case ForgotPasswordStep.success:
        return _buildSuccessStep(context);
    }
  }

  // ================= STEP 1: ENTER EMAIL =================
  Widget _buildEmailStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderLogo(context),
          const SizedBox(height: AppSpacing.s16),
          _buildStepBadge(context, 'STEP 1 OF 3'),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Enter your registered institutional email to receive a single-use 6-digit OTP code.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          _buildErrorBanner(),
          CampusTextField(
            controller: _emailController,
            label: 'Registered Institutional Email',
            hint: 'name@gcee.ac.in',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your institutional email';
              }
              final email = val.trim();
              if (!email.contains('@') || !email.contains('.')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          CampusButton.primary(
            label: 'Send Verification OTP →',
            isLoading: _isLoading,
            onPressed: _handleSendOtp,
          ),
          const SizedBox(height: AppSpacing.s12),
          CampusButton.ghost(
            label: 'Return to Sign In',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: ENTER OTP =================
  Widget _buildOtpStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Form(
      key: _otpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderLogo(context),
          const SizedBox(height: AppSpacing.s16),
          _buildStepBadge(context, 'STEP 2 OF 3'),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Enter 6-Digit OTP',
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'We sent a verification code to ${_emailController.text.trim()}.\nEnter the 6 digits below (expires in 15 mins).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          _buildErrorBanner(),
          CampusTextField(
            controller: _otpController,
            label: '6-Digit Verification Code',
            hint: '123456',
            prefixIcon: Icons.security_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (val) {
              if (val == null || val.trim().length != 6) {
                return 'Please enter the complete 6-digit OTP code';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          Center(
            child: _secondsRemaining > 0
                ? Text(
                    'Resend code in ${_secondsRemaining}s',
                    style: AppTypography.captionMedium.copyWith(color: secondary),
                  )
                : TextButton.icon(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Resend 6-Digit OTP'),
                  ),
          ),
          const SizedBox(height: AppSpacing.s16),
          CampusButton.primary(
            label: 'Verify Code →',
            isLoading: _isLoading,
            onPressed: _handleVerifyOtp,
          ),
          const SizedBox(height: AppSpacing.s12),
          CampusButton.ghost(
            label: '← Change Email Address',
            onPressed: () {
              setState(() {
                _currentStep = ForgotPasswordStep.enterEmail;
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ================= STEP 3: SET NEW PASSWORD =================
  Widget _buildNewPasswordStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final score = _calculateStrength(_passwordController.text);

    return Form(
      key: _passwordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderLogo(context),
          const SizedBox(height: AppSpacing.s16),
          _buildStepBadge(context, 'STEP 3 OF 3'),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Set New Password',
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Your identity has been verified. Create your new secure password.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          _buildErrorBanner(),
          CampusTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            onChanged: (val) => setState(() {}),
            validator: (val) {
              if (val == null || val.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score / 4.0,
                      backgroundColor: isDark ? const Color(0x3310243D) : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(score)),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  _getStrengthLabel(score),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStrengthColor(score),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          CampusTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_reset_outlined,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          CampusButton.primary(
            label: 'Update Password & Save →',
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),
        ],
      ),
    );
  }

  // ================= STEP 4: SUCCESS =================
  Widget _buildSuccessStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Text(
          'Password Reset Complete!',
          textAlign: TextAlign.center,
          style: AppTypography.pageTitle.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Your password has been successfully updated. All previous sessions have been invalidated for your security.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: secondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.s28),
        CampusButton.primary(
          label: 'Proceed to Sign In →',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
