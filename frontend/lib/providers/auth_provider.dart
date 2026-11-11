import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'chat_provider.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  otpSent,
  onboardingRequired,
  authenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final Map<String, dynamic>? profile;

  AuthState({
    required this.status,
    this.email,
    this.errorMessage,
    this.profile,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
    Map<String, dynamic>? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: errorMessage ?? this.errorMessage,
      profile: profile ?? this.profile,
    );
  }
}

// Provider for ApiService so it can be injected
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService();
  return apiService;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;

  AuthNotifier(this._apiService, this._ref) : super(AuthState.initial()) {
    _checkSavedAuth();
  }

  // Attempt auto-login if a token is saved
  Future<void> _checkSavedAuth() async {
    try {
      await _apiService.init();
      if (_apiService.token != null) {
        state = state.copyWith(status: AuthStatus.loading);
        try {
          final profile = await _apiService.getProfile();
          state = AuthState(
            status: AuthStatus.authenticated,
            profile: profile,
          );
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('Profile not found')) {
            state = AuthState(status: AuthStatus.onboardingRequired);
          } else {
            await _apiService.logout();
            state = AuthState(status: AuthStatus.unauthenticated);
          }
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Initialisation failed: $e',
      );
    }
  }

  // Initiate OTP flow
  Future<void> sendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiService.sendOtp(email);
      state = state.copyWith(status: AuthStatus.otpSent, email: email);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otp) async {
    final email = state.email;
    if (email == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please enter email again.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiService.verifyOtp(email, otp);
      final isNewUser = res['isNewUser'] ?? false;

      if (isNewUser) {
        state = state.copyWith(status: AuthStatus.onboardingRequired);
      } else {
        final profile = await _apiService.getProfile();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          profile: profile,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Bypass Auth flow for development
  Future<void> bypassAuth(String emailOrPhone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      // Use fake OTP 1234 on API
      final email = emailOrPhone.contains('@') ? emailOrPhone : '$emailOrPhone@example.com';
      await _apiService.sendOtp(email);
      final res = await _apiService.verifyOtp(email, '1234');
      final isNewUser = res['isNewUser'] ?? false;

      if (isNewUser) {
        state = state.copyWith(status: AuthStatus.onboardingRequired, email: email);
      } else {
        final profile = await _apiService.getProfile();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          profile: profile,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Submit complete onboarding details
  Future<void> submitOnboarding({
    required String name,
    required String city,
    required int age,
    required DateTime dob,
    required String gender,
    required String interestedIn,
    String? tob,
    String? pob,
    String? subCaste,
    String? gothram,
    String? rasi,
    String? star,
    String? education,
    String? occupation,
    Map<String, dynamic>? familyDetails,
    List<File>? photos,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiService.createProfile(
        name: name,
        city: city,
        age: age,
        dob: dob,
        gender: gender,
        interestedIn: interestedIn,
        tob: tob,
        pob: pob,
        subCaste: subCaste,
        gothram: gothram,
        rasi: rasi,
        star: star,
        education: education,
        occupation: occupation,
        familyDetails: familyDetails,
        photos: photos,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        email: state.email,
        profile: res['profile'],
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.onboardingRequired,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Update profile from external triggers (e.g. rose boutique balance updates)
  void updateProfile(Map<String, dynamic> updatedProfile) {
    if (state.profile != null) {
      state = state.copyWith(profile: updatedProfile);
    }
  }

  // Face Verification Upload
  Future<bool> verifyFace(File selfie) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiService.verifyFace(selfie);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: res['profile'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated, // return to authenticated
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Aadhaar Verification Check
  Future<bool> verifyAadhaar(String aadhaarNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiService.verifyAadhaar(aadhaarNumber);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: res['profile'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Toggle phone visibility
  Future<void> togglePhoneVisibility(bool isVisible) async {
    try {
      final res = await _apiService.updateSettings(isVisible);
      state = state.copyWith(profile: res['profile']);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    _ref.read(chatProvider.notifier).disconnectSocket();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  // Clear current error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Global Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthNotifier(apiService, ref);
});
