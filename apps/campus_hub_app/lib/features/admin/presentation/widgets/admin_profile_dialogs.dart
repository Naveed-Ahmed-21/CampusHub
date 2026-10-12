import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../providers/admin_provider.dart';

class AdminProfileDialogs {
  const AdminProfileDialogs._();

  // =========================================================================
  // 1. EDIT PROFILE DIALOG (SAFE FIELDS ONLY)
  // =========================================================================
  static void showEditProfile(
    BuildContext context,
    WidgetRef ref, {
    required dynamic user,
    required UserProfile? profile,
  }) {
    final firstCtrl = TextEditingController(
      text: user?.firstName ?? profile?.firstName ?? '',
    );
    final lastCtrl = TextEditingController(
      text: user?.lastName ?? profile?.lastName ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: user?.phone ?? profile?.phone ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Edit Administrator Profile'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: firstCtrl,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email, Role, Institution, and Administrative Scope are immutable institutional records and cannot be altered here.',
                        style: TextStyle(fontSize: 11, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final fName = firstCtrl.text.trim();
              final lName = lastCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (fName.isEmpty) return;

              Navigator.pop(ctx);
              try {
                if (user != null) {
                  // 1. Update Profile Controller
                  await ref.read(profileControllerProvider.notifier).updateProfile(
                        firstName: fName,
                        lastName: lName,
                        phone: phone.isNotEmpty ? phone : null,
                      );

                  // 2. Update Admin User record in Remote DataSource
                  await ref.read(adminRemoteDataSourceProvider).updateUser(user.id, {
                    'firstName': fName,
                    'lastName': lName,
                    if (phone.isNotEmpty) 'phone': phone,
                  });

                  // 3. Update AuthUser local state
                  final updatedUser = user.copyWith(
                    firstName: fName,
                    lastName: lName,
                    phone: phone.isNotEmpty ? phone : user.phone,
                  );
                  ref.read(authControllerProvider.notifier).updateUser(updatedUser);

                  ref.invalidate(adminUsersProvider);
                  ref.invalidate(authControllerProvider);
                  ref.invalidate(profileControllerProvider);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Administrator profile updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. CHANGE PASSWORD DIALOG (SECURE WORKFLOW)
  // =========================================================================
  static void showChangePassword(BuildContext context, WidgetRef ref) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Change Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 6 chars) *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentPass = currentPasswordCtrl.text.trim();
                        final newPass = newPasswordCtrl.text.trim();
                        final confirmPass = confirmPasswordCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);

                        if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('All password fields are required.')),
                          );
                          return;
                        }

                        if (newPass.length < 6) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('New password must be at least 6 characters.')),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('New passwords do not match.')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await ref.read(authRemoteDataSourceProvider).changePassword(
                                currentPassword: currentPass,
                                newPassword: newPass,
                              );
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Password change failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // 3. MANAGE ACTIVE SESSIONS DIALOG
  // =========================================================================
  static void showActiveSessions(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.devices_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Active Session Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current authenticated session:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Administrative Console',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active Session • Authenticated via JWT TLS token',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
