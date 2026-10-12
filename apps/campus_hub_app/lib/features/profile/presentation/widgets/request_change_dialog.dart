import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_dialog.dart';
import '../../../../core/widgets/campus_text_field.dart';

class RequestChangeDialog extends ConsumerStatefulWidget {
  final String fieldName;
  final String fieldDisplayName;
  final String category;
  final String currentValue;
  final VoidCallback? onSuccess;

  const RequestChangeDialog({
    super.key,
    required this.fieldName,
    required this.fieldDisplayName,
    required this.category,
    required this.currentValue,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String fieldName,
    required String fieldDisplayName,
    required String category,
    required String currentValue,
    VoidCallback? onSuccess,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => RequestChangeDialog(
        fieldName: fieldName,
        fieldDisplayName: fieldDisplayName,
        category: category,
        currentValue: currentValue,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<RequestChangeDialog> createState() => _RequestChangeDialogState();
}

class _RequestChangeDialogState extends ConsumerState<RequestChangeDialog> {
  final _requestedValueCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _supportingDocCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _requestedValueCtrl.dispose();
    _reasonCtrl.dispose();
    _supportingDocCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/api/v1/profile/change-requests', data: {
        'field': widget.fieldName,
        'category': widget.category,
        'requestedValue': _requestedValueCtrl.text.trim(),
        'reason': _reasonCtrl.text.trim(),
        if (_supportingDocCtrl.text.trim().isNotEmpty)
          'supportingDocument': _supportingDocCtrl.text.trim(),
      });

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correction request for ${widget.fieldDisplayName} submitted for admin review.'),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = e.toString().contains('already pending')
          ? 'A request for this field is already pending review.'
          : 'Failed to submit request. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CampusDialog(
      maxWidth: 520,
      icon: Icon(
        Icons.edit_document,
        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
        size: 24,
      ),
      title: 'Request Correction: ${widget.fieldDisplayName}',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info notice
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.electricBlue : AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Text(
                        'Profile changes to institutional fields require administrator approval with justification.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkText : AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Current Value Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Value on Record',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentValue.isEmpty ? 'Not Set' : widget.currentValue,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s14),

              // Requested Value Input
              CampusTextField(
                controller: _requestedValueCtrl,
                label: 'Requested New Value',
                prefixIcon: Icons.edit_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requested value is required';
                  if (val.trim() == widget.currentValue.trim()) {
                    return 'Requested value must be different from current value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s14),

              // Reason Input
              CampusTextField(
                controller: _reasonCtrl,
                label: 'Reason for Change (Min 5 characters)',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please provide a clear reason (at least 5 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s14),

              // Supporting Document URL / Reference
              CampusTextField(
                controller: _supportingDocCtrl,
                label: 'Supporting Document URL / Reference (Optional)',
                prefixIcon: Icons.attach_file_rounded,
              ),
            ],
          ),
        ),
      ),
      actions: [
        CampusButton(
          label: 'Cancel',
          type: CampusButtonType.ghost,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.s8),
        CampusButton(
          label: 'Submit Request',
          type: CampusButtonType.primary,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submit,
        ),
      ],
    );
  }
}
