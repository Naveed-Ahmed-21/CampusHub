import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/server_health_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../../../core/branding/campushub_brand.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../controllers/auth_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _loginErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Skip real network calls during headless widget tests
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(serverHealthServiceProvider.notifier).checkHealth();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(serverHealthServiceProvider.notifier).checkHealth();
    }
  }

  void _onLogin() async {
    setState(() => _loginErrorMessage = null);
    if (_formKey.currentState?.validate() ?? false) {
      final serverStatus = ref.read(serverHealthServiceProvider);
      if (serverStatus.isOffline) {
        await ref.read(serverHealthServiceProvider.notifier).checkHealth();
        if (ref.read(serverHealthServiceProvider).isOffline && mounted) {
          setState(() {
            _loginErrorMessage =
                'Backend server is offline or unreachable (${serverStatus.activeUrl}). Please check server status or tap the connection badge above.';
          });
          return;
        }
      }

      final email = _emailController.text.trim();
      final success = await ref.read(authControllerProvider.notifier).login(
            email,
            _passwordController.text.trim(),
          );
      if (!success && mounted) {
        final error = ref.read(authControllerProvider).asError?.error;
        final errorMsg = error != null
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Login failed. Check server connection and credentials.';

        if (errorMsg.toLowerCase().contains('activated') ||
            errorMsg.toLowerCase().contains('password')) {
          showDialog(
            context: context,
            builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
                title: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: isDark ? Colors.white : AppColors.primaryText),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Account Activation Required'),
                    ),
                  ],
                ),
              content: Text(
                'Your account has been provisioned by college administration. Please set up your password to activate your account.\n\nAccount: $email',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.key),
                  label: const Text('Activate Account'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/setup-password?email=$email');
                  },
                ),
              ],
            );
          },
        );
        } else {
          setState(() {
            _loginErrorMessage = errorMsg;
          });
        }
      }
    }
  }

  void _showServerSettingsDialog(BuildContext context) {
    final customUrlCtrl = TextEditingController(text: ApiEndpoints.baseUrl);
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
            title: Row(
              children: [
                Icon(Icons.dns_rounded, color: isDark ? Colors.white : AppColors.primaryText),
                const SizedBox(width: 8),
                const Text('Server Connection'),
              ],
            ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select connection mode or enter custom backend URL:',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.usb, size: 16),
                      label: const Text('USB / Localhost (5000)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://localhost:5000';
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16),
                      label: const Text('Emulator (10.0.2.2)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://10.0.2.2:5000';
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.settings_ethernet, size: 16),
                      label: const Text('Loopback (127.0.0.1)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://127.0.0.1:5000';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.radar_rounded, size: 16),
                  label: const Text('Auto-Detect Working Server'),
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() => isTesting = true);
                          await ref
                              .read(serverHealthServiceProvider.notifier)
                              .autoDetectServer();
                          customUrlCtrl.text = ApiEndpoints.baseUrl;
                          setDialogState(() => isTesting = false);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    hintText: 'http://192.168.1.100:5000',
                  ),
                ),
                const SizedBox(height: 12),
                if (isTesting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isTesting
                  ? null
                  : () async {
                      setDialogState(() => isTesting = true);
                      final url = customUrlCtrl.text.trim();
                      ApiEndpoints.setBaseUrl(url);

                      await ref
                          .read(serverHealthServiceProvider.notifier)
                          .checkHealth();
                      final isOk = ref.read(serverHealthServiceProvider).state == ServerConnectionState.connected;

                      setDialogState(() => isTesting = false);

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOk
                                  ? 'Successfully connected to backend: $url'
                                  : 'Could not connect to $url. Check Wi-Fi/port forwarding.',
                            ),
                            backgroundColor: isOk ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              child: const Text('Save & Connect'),
            ),
          ],
        );
      },
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: AtmosphericBackground(
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context, isLoading),
          desktop: _buildDesktopLayout(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final serverStatus = ref.watch(serverHealthServiceProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Status Pill Badge
          Center(
            child: InkWell(
              borderRadius: AppRadius.br20,
              onTap: () => _showServerSettingsDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: serverStatus.isConnected
                      ? AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1)
                      : AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: AppRadius.br20,
                  border: Border.all(
                    color: serverStatus.isConnected
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.warning.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      serverStatus.isConnected ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      size: 13,
                      color: serverStatus.isConnected ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      serverStatus.isConnected
                          ? 'Server Online (${serverStatus.activeUrl})'
                          : 'Server Offline / Tap to Configure',
                      style: AppTypography.micro.copyWith(
                        color: serverStatus.isConnected
                            ? (isDark ? const Color(0xFF4ADE80) : AppColors.success)
                            : (isDark ? const Color(0xFFFBBF24) : AppColors.warning),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.tune_rounded, size: 12, color: secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          // Header Text
          Text(
            'Welcome Back',
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Sign in to your GCEE CampusHub account',
            style: AppTypography.body.copyWith(
              color: secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          CampusTextField(
            controller: _emailController,
            label: 'Institutional Email / Username',
            hint: 'name@gcee.ac.in or username',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your registered email';
              }
              final email = val.trim();
              if (email.toLowerCase() != 'admin' && (!email.contains('@') || !email.contains('.'))) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          CampusTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: secondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter password' : null,
          ),
          const SizedBox(height: AppSpacing.s8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Forgot Password?',
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          // Premium Non-Disturbing Error Notification Banner
          if (_loginErrorMessage != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: AppRadius.br12,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: isDark ? 0.4 : 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loginErrorMessage!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFFCA5A5) : AppColors.error,
                            height: 1.3,
                          ),
                        ),
                        if (_loginErrorMessage!.toLowerCase().contains('connection') ||
                            _loginErrorMessage!.toLowerCase().contains('server') ||
                            _loginErrorMessage!.toLowerCase().contains('connect') ||
                            _loginErrorMessage!.toLowerCase().contains('failed')) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showServerSettingsDialog(context),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.dns_outlined, size: 13, color: isDark ? Colors.white : AppColors.primaryText),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Server Connection Settings',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.primaryText,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: isDark ? Colors.white60 : Colors.black54,
                    tooltip: 'Dismiss',
                    onPressed: () => setState(() => _loginErrorMessage = null),
                  ),
                ],
              ),
            ),
          ],

          CampusButton.primary(
            label: 'Sign In →',
            isLoading: isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: AppSpacing.s16),

          CampusButton.secondary(
            label: 'First Time Logging In? Activate Account',
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            onPressed: () {
              final email = _emailController.text.trim();
              context.push('/setup-password?email=$email');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: CampusHubBrand.login(),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Glass Login Card
            CampusGlassCard(
              intensity: GlassIntensity.strong,
              borderRadius: AppRadius.br24,
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: _buildForm(context, isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CampusHubBrand.login(),
              ),
              const SizedBox(height: AppSpacing.s32),
              CampusGlassCard(
                intensity: GlassIntensity.strong,
                borderRadius: AppRadius.br24,
                padding: const EdgeInsets.all(AppSpacing.s32),
                child: _buildForm(context, isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
