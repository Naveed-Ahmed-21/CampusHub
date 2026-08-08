import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check credentials.')),
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
        content: Text('Selected $roleName sample account ($email)'),
        duration: const Duration(seconds: 2),
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

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.school, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'CampusHub Portal',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your institutional credentials',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 24),

          // Sample Accounts Quick Role Selection Bar
          Text(
            'Sample Accounts (Select Role):',
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
          const SizedBox(height: 24),

          CustomTextField(
            controller: _emailController,
            label: 'Campus Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || val.isEmpty ? 'Please enter email' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (val) => val == null || val.isEmpty ? 'Please enter password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: 24),

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
                    'Accounts are provisioned by Campus Administration. Contact your administrator if you need access.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SingleChildScrollView(
          child: _buildForm(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            color: theme.colorScheme.primaryContainer,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hub,
                      size: 120,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to CampusHub',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unified Digital Academic & Extracurricular Platform',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(32.0),
              child: _buildForm(context, isLoading),
            ),
          ),
        ),
      ],
    );
  }
}
