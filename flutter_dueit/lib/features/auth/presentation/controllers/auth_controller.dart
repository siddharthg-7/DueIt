import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isBusinessSetupComplete =>
      user != null && user!.isSetupComplete && user!.businessName.isNotEmpty;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthController(this._repository) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authSubscription = _repository.authStateChanges().listen(
      (user) {
        state = state.copyWith(
          user: user,
          clearUser: user == null,
          isInitialized: true,
          isLoading: false,
        );
      },
      onError: (err) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          error: err.toString(),
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> reloadUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.reloadCurrentUser();
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
        isInitialized: true,
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> saveBusinessProfile({
    required String businessName,
    required String businessType,
    String? description,
    String? ownerName,
    String? phone,
    String? upiId,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = BusinessProfile(
        id: currentUser.id,
        ownerId: currentUser.id,
        businessName: businessName.trim(),
        businessType: businessType,
        description: description?.trim(),
        ownerName: ownerName?.trim(),
        phone: phone?.trim(),
        upiId: upiId?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.saveBusinessProfile(profile);

      final updatedUser = currentUser.copyWith(
        businessName: profile.businessName,
        businessType: profile.businessType,
        ownerName: profile.ownerName,
        phone: profile.phone,
        upiId: profile.upiId,
        isSetupComplete: true,
        profile: profile,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> updateProfile(UserEntity profile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateBusinessProfile(profile);
      state = state.copyWith(user: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage:
            "If an account exists for this email, we've sent instructions to reset your password.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
    } finally {
      state = const AuthState(isInitialized: true);
    }
  }

  String _cleanErrorMessage(Object error) {
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

/// Listenable adapter to notify GoRouter when auth state changes
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}

final authStateListenableProvider = Provider<AuthStateListenable>((ref) {
  return AuthStateListenable(ref);
});
