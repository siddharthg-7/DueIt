import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Trigger initial auth check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).reloadUser();
    });
  }

  void _checkAndNavigate(AuthState authState) {
    if (_hasNavigated || !mounted || !authState.isInitialized) return;

    _hasNavigated = true;
    if (!authState.isAuthenticated) {
      context.go(RouteNames.welcome);
    } else if (!authState.isBusinessSetupComplete) {
      context.go(RouteNames.businessSetup);
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen for state changes
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next.isInitialized && !_hasNavigated) {
        _checkAndNavigate(next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: GestureDetector(
        onTap: () => _checkAndNavigate(authState),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient Radial Glows
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.5 - 150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                ),
              ),
            ),

            // Main Brand Centerpiece
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 48,
                                color: AppColors.primaryFixed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Brand Wordmark
                          Text(
                            'DueIt',
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Tagline
                          Text(
                            "Know what you're owed. Never miss a payment.",
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primaryFixed,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Progress Line
                          SizedBox(
                            width: 160,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryFixed,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  authState.isInitialized
                                      ? 'READY'
                                      : 'INITIALIZING...',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primaryFixedDim,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
