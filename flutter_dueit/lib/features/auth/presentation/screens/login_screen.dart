import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isSignIn = !widget.initialIsSignUp;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsSignUp ? 1 : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _isSignIn = _tabController.index == 0;
        });
        ref.read(authControllerProvider.notifier).clearError();
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authControllerProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignIn) {
      final success = await ref.read(authControllerProvider.notifier).signIn(
            email,
            password,
          );
      if (success && mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState.isBusinessSetupComplete) {
          context.go(RouteNames.dashboard);
        } else {
          context.go(RouteNames.businessSetup);
        }
      }
    } else {
      final success = await ref.read(authControllerProvider.notifier).signUp(
            email: email,
            password: password,
          );
      if (success && mounted) {
        context.go(RouteNames.businessSetup);
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isSubmittingReset = false;
    String? resetSuccessMsg;
    String? resetErrorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Reset Password',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your registered email address and we'll send you instructions to reset your password.",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (resetSuccessMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              resetSuccessMsg!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSuccessContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Back to Sign In',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ] else ...[
                    if (resetErrorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppColors.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorContainer),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                resetErrorMsg!,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Form(
                      key: resetFormKey,
                      child: TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@business.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(val.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Send Instructions',
                      isLoading: isSubmittingReset,
                      onPressed: () async {
                        if (resetFormKey.currentState?.validate() ?? false) {
                          setModalState(() {
                            isSubmittingReset = true;
                            resetErrorMsg = null;
                          });

                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .sendPasswordResetEmail(
                                    resetEmailController.text.trim());
                            setModalState(() {
                              isSubmittingReset = false;
                              resetSuccessMsg =
                                  "If an account exists for this email, we've sent instructions to reset your password.";
                            });
                          } catch (e) {
                            setModalState(() {
                              isSubmittingReset = false;
                              var msg = e.toString();
                              if (msg.startsWith('Exception: ')) {
                                msg = msg.substring(11);
                              }
                              resetErrorMsg = msg;
                            });
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // App Branding Header
                      Hero(
                        tag: 'app_logo_hero',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 38,
                            color: AppColors.primaryFixed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DueIt',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignIn
                            ? 'Welcome back! Log in to manage collections.'
                            : 'Create an account to start tracking dues.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),

                      // Custom Sliding Tab Selector
                      Container(
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.onSurfaceVariant,
                          labelStyle: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle:
                              AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Create Account'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Form Inputs
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error Banner
                            if (authState.error != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.errorContainer),
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
                              const SizedBox(height: 20),
                            ],

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !authState.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'name@business.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(val.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: !authState.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            // Confirm Password (Sign Up Only)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: Column(
                                children: [
                                  if (!_isSignIn) ...[
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      enabled: !authState.isLoading,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        prefixIcon:
                                            const Icon(Icons.lock_reset),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (_isSignIn) return null;
                                        if (val == null || val.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (val != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Forgot Password link (Sign In only)
                            if (_isSignIn) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : _showForgotPasswordSheet,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  _isSignIn ? 'Sign In' : 'Create Account',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
