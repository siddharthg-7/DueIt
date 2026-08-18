import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/constants/app_constants.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _businessNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _upiIdCtrl;
  String _selectedBusinessType = AppConstants.businessTypes.first;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _businessNameCtrl = TextEditingController(text: user?.businessName ?? '');
    _ownerNameCtrl = TextEditingController(text: user?.ownerName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _upiIdCtrl = TextEditingController(text: user?.upiId ?? '');
    if (user != null && AppConstants.businessTypes.contains(user.businessType)) {
      _selectedBusinessType = user.businessType;
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Settings',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Account Summary Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.businessName.isNotEmpty == true) ? user!.businessName[0] : 'D',
                    style: const TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.businessName ?? 'Business Name',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${user?.email ?? ''} • ${user?.businessType ?? ''}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Business Details Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Business Profile Details', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                Text('Business / Academy Name *', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                TextField(controller: _businessNameCtrl),
                const SizedBox(height: 14),

                Text('Owner / Instructor Name *', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                TextField(controller: _ownerNameCtrl),
                const SizedBox(height: 14),

                Text('Business Type', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBusinessType,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  items: AppConstants.businessTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBusinessType = val);
                  },
                ),
                const SizedBox(height: 14),

                Text('Phone Number (for contact & SMS)', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),

                Text('UPI ID / VPA (Included in WhatsApp links)', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: _upiIdCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. name@okhdfcbank'),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () async {
                      if (user != null) {
                        final updated = user.copyWith(
                          businessName: _businessNameCtrl.text.trim(),
                          ownerName: _ownerNameCtrl.text.trim(),
                          businessType: _selectedBusinessType,
                          phone: _phoneCtrl.text.trim(),
                          upiId: _upiIdCtrl.text.trim(),
                        );
                        await ref.read(authControllerProvider.notifier).updateProfile(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved successfully!')),
                          );
                        }
                      }
                    },
                    child: const Text('Save Profile Settings'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sign Out & Version Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/splash');
                  },
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorContainer),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'DueIt v1.0.0 (Production Build)',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
