import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isOnboardingDone;

  AuthState({
    required this.isAuthenticated,
    required this.isBiometricEnabled,
    required this.isBiometricAvailable,
    required this.isOnboardingDone,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isOnboardingDone,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricKey = 'biometric_enabled';
  static const String _onboardingKey = 'onboarding_done';

  AuthNotifier()
      : super(AuthState(
          isAuthenticated: false,
          isBiometricEnabled: false,
          isBiometricAvailable: false,
          isOnboardingDone: false,
        )) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    final onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    bool biometricAvailable = false;

    try {
      biometricAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {}

    state = AuthState(
      isAuthenticated: !biometricEnabled,
      isBiometricEnabled: biometricEnabled,
      isBiometricAvailable: biometricAvailable,
      isOnboardingDone: onboardingDone,
    );

    if (biometricEnabled && !state.isAuthenticated) {
      await authenticate();
    }
  }

  Future<bool> authenticate() async {
    if (!state.isBiometricEnabled) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }

    try {
      final result = await _auth.authenticate(
        localizedReason: 'Unlock GenPay',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) {
        state = state.copyWith(isAuthenticated: true);
      }
      return result;
    } catch (_) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }
  }

  Future<void> toggleBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(isOnboardingDone: true, isAuthenticated: true);
  }

  void lock() {
    if (state.isBiometricEnabled) {
      state = state.copyWith(isAuthenticated: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
