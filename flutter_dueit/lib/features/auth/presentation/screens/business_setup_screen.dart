import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/shared/widgets/app_text_field.dart';
import 'package:dueit/shared/widgets/primary_button.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';

/// DueIt Business Setup Screen (matches Google Stitch design)
class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedBusinessType = 'Karate / Martial Arts';

  final List<String> _businessTypes = [
    'Karate / Martial Arts',
    'Gym / Fitness Center',
    'Tuition / Coaching',
    'Yoga Studio',
    'Dance Academy',
    'Freelancer / Consultant',
    'Other Service Business',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    ref.read(authControllerProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).saveBusinessProfile(
              businessName: _businessNameController.text.trim(),
              businessType: _selectedBusinessType,
              description: _descriptionController.text.trim(),
            );

    if (success && mounted) {
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'DueIt',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Let's set up your business profile.",
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.surfaceVariant, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Banner if present
                        if (authState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.errorContainer),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        AppTextField(
                          controller: _businessNameController,
                          label: 'Business Name',
                          isRequired: true,
                          hintText: 'e.g. Apex Martial Arts Academy',
                          prefixIcon: Icons.storefront_outlined,
                          enabled: !authState.isLoading,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Please enter your business name'
                                  : null,
                        ),
                        const SizedBox(height: 18),

                        // Business Type Dropdown
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                'Business Type',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' *',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBusinessType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.outlineVariant, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.outlineVariant, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          items: _businessTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: AppTypography.bodyLarge
                                    .copyWith(color: AppColors.onSurface),
                              ),
                            );
                          }).toList(),
                          onChanged: authState.isLoading
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _selectedBusinessType = val);
                                  }
                                },
                        ),
                        const SizedBox(height: 18),

                        AppTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          hintText: 'Brief summary of services provided...',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 3,
                          enabled: !authState.isLoading,
                        ),
                        const SizedBox(height: 24),

                        PrimaryButton(
                          label: 'Save & Continue',
                          icon: Icons.arrow_forward,
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading ? null : _onContinue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Security footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Your data is secure and encrypted with Firebase',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
