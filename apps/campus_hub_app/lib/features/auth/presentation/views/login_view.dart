import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/server_health_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../controllers/auth_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController(text: 'student@campushub.edu');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!success && mounted) {
        final error = ref.read(authControllerProvider).asError?.error;
        final errorMsg = error != null
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Login failed. Check server connection and credentials.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Server Settings',
              textColor: Colors.white,
              onPressed: () => _showServerSettingsDialog(context),
            ),
          ),
        );
      }
    }
  }

  void _selectSampleAccount(String email, String roleName) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'Password@123';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $roleName credentials ($email / Password@123)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showServerSettingsDialog(BuildContext context) {
    final customUrlCtrl = TextEditingController(text: ApiEndpoints.baseUrl);
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns, color: Colors.blue),
              SizedBox(width: 8),
              Text('Server Connection'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select connection mode or enter custom backend URL:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.usb, size: 16),
                      label: const Text('USB (localhost)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://localhost:5000';
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 16),
                      label: const Text('Wi-Fi (172.18.15.11)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://172.18.15.11:5000';
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16),
                      label: const Text('Emulator (10.0.2.2)'),
                      onPressed: () {
                        customUrlCtrl.text = 'http://10.0.2.2:5000';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: customUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Auto-Detect Working Server'),
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() => isTesting = true);
                          await ref.read(serverHealthServiceProvider.notifier).checkHealth();
                          setDialogState(() {
                            isTesting = false;
                            customUrlCtrl.text = ApiEndpoints.baseUrl;
                          });
                        },
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
                      await ref.read(serverHealthServiceProvider.notifier).setCustomUrl(customUrlCtrl.text);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        final status = ref.read(serverHealthServiceProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(status.isConnected
                                ? 'Connected to backend: ${status.activeUrl}'
                                : 'Failed to connect to ${status.activeUrl}. Check that backend is running.'),
                            backgroundColor: status.isConnected ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, isLoading),
        desktop: _buildDesktopLayout(context, isLoading),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
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
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showServerSettingsDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: serverStatus.isConnected
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: serverStatus.isConnected
                        ? Colors.green.shade400
                        : Colors.orange.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      serverStatus.isConnected ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 14,
                      color: serverStatus.isConnected ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      serverStatus.isConnected
                          ? 'Server Online (${serverStatus.activeUrl})'
                          : 'Server Offline / Tap to Configure',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: serverStatus.isConnected ? Colors.green.shade800 : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.settings, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Icon(Icons.school, size: 60, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            'CampusHub Portal',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in with your institutional credentials',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 20),

          // Quick Role Selector Chips
          Text(
            'Quick Sign-in (Select Role):',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person, size: 16, color: Colors.blue),
                label: const Text('Student'),
                onPressed: () => _selectSampleAccount('student@campushub.edu', 'Student'),
              ),
              ActionChip(
                avatar: const Icon(Icons.school, size: 16, color: Colors.purple),
                label: const Text('Faculty'),
                onPressed: () => _selectSampleAccount('faculty@campushub.edu', 'Faculty'),
              ),
              ActionChip(
                avatar: const Icon(Icons.work, size: 16, color: Colors.orange),
                label: const Text('Placement Officer'),
                onPressed: () => _selectSampleAccount('placement@campushub.edu', 'Placement Officer'),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.red),
                label: const Text('Admin'),
                onPressed: () => _selectSampleAccount('admin@campushub.edu', 'Admin'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          CustomTextField(
            controller: _emailController,
            label: 'Campus Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter email' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: 20),

          // Admin Provisioning Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.security, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Default Password for all seeded accounts is: Password@123',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _buildForm(context, isLoading),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(32.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildForm(context, isLoading),
          ),
        ),
      ),
    );
  }
}
