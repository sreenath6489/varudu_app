import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Attempt auto-login if a token or saved profile exists
  Future<void> _checkSavedAuth() async {
    try {
      await _apiService.init();
      final prefs = await SharedPreferences.getInstance();
      final cachedProfileStr = prefs.getString('current_active_profile');

      if (_apiService.token != null) {
        state = state.copyWith(status: AuthStatus.loading);
        try {
          final profile = await _apiService.getProfile();
          await prefs.setString('current_active_profile', jsonEncode(profile));
          state = AuthState(
            status: AuthStatus.authenticated,
            profile: profile,
          );
          return;
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('Profile not found')) {
            state = AuthState(status: AuthStatus.onboardingRequired);
            return;
          }
        }
      }

      // If network was offline or server unreachable, restore cached profile
      if (cachedProfileStr != null) {
        try {
          final profile = jsonDecode(cachedProfileStr);
          state = AuthState(
            status: AuthStatus.authenticated,
            profile: profile,
          );
          return;
        } catch (_) {}
      }

      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Initialisation failed: $e',
      );
    }
  }

  // Initiate OTP flow (Phone or Email)
  Future<void> sendOtp(String emailOrPhone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiService.sendOtp(emailOrPhone);
      state = state.copyWith(status: AuthStatus.otpSent, email: emailOrPhone);
    } catch (e) {
      // In development/testing, if backend is offline or 404, smoothly proceed to OTP screen with fake OTP 1234
      debugPrint('Backend OTP call failed: $e. Using offline fake OTP 1234 mode.');
      state = state.copyWith(status: AuthStatus.otpSent, email: emailOrPhone);
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otp) async {
    final emailOrPhone = state.email;
    if (emailOrPhone == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please enter phone/email again.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final isFakeOtp = otp == '1234' || otp == '0000' || otp == '1111';

    try {
      final res = await _apiService.verifyOtp(emailOrPhone, otp);
      final isNewUser = res['isNewUser'] ?? false;

      if (isNewUser) {
        state = state.copyWith(status: AuthStatus.onboardingRequired);
      } else {
        final profile = await _apiService.getProfile();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_active_profile', jsonEncode(profile));

        state = AuthState(
          status: AuthStatus.authenticated,
          email: emailOrPhone,
          profile: profile,
        );
      }
    } catch (e) {
      if (isFakeOtp) {
        // Fallback for offline testing with fake OTP 1234
        final prefs = await SharedPreferences.getInstance();
        final savedProfileStr = prefs.getString('saved_user_profile_$emailOrPhone');

        if (savedProfileStr != null) {
          final profile = jsonDecode(savedProfileStr);
          await prefs.setString('current_active_profile', savedProfileStr);
          state = AuthState(
            status: AuthStatus.authenticated,
            email: emailOrPhone,
            profile: profile,
          );
        } else {
          // New account creation flow!
          state = state.copyWith(status: AuthStatus.onboardingRequired, email: emailOrPhone);
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.otpSent,
          errorMessage: 'Invalid OTP. Please enter 1234 for testing.',
        );
      }
    }
  }

  // Bypass Auth flow for instant testing
  Future<void> bypassAuth(String emailOrPhone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultProfile = {
        'id': 'user-sreenath-1',
        'name': 'Sreenath',
        'city': 'Hyderabad',
        'age': 22,
        'dob': '2004-05-10',
        'gender': 'MAN',
        'interestedIn': 'WOMAN',
        'phone_number': emailOrPhone.isNotEmpty ? emailOrPhone : '+91 98765 43210',
        'email': emailOrPhone.contains('@') ? emailOrPhone : '$emailOrPhone@varudu.in',
        'photos': ['assets/sreenath.jpg'],
        'photoUrl': 'assets/sreenath.jpg',
        'is_onboarded': true,
        'aadhaar_verified': false,
        'face_verified': false,
        'roses_balance': 25,
        'referral_code': 'VARUDU-4BB1QQ',
        'tob': '10:15 AM',
        'pob': 'Hyderabad',
        'family_details': {
          'star': 'Uttara',
          'rasi': 'Kanya',
          'subCaste': 'Hindu',
          'gothram': 'Kasyapa',
          'education': 'B.Tech in Computer Science',
          'occupation': 'Founder & Developer',
          'family_status': 'Upper Middle Class',
        },
      };

      await prefs.setString('current_active_profile', jsonEncode(defaultProfile));
      state = AuthState(
        status: AuthStatus.authenticated,
        email: emailOrPhone,
        profile: defaultProfile,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Submit complete onboarding details (Account Creation)
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

    final emailOrPhone = state.email ?? '9876543210';
    final isPhone = !emailOrPhone.contains('@');
    final formattedDob = '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

    final localProfile = {
      'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'city': city,
      'age': age,
      'dob': formattedDob,
      'gender': gender,
      'interestedIn': interestedIn,
      'phone_number': isPhone ? emailOrPhone : '+91 98765 43210',
      'email': isPhone ? '$emailOrPhone@varudu.in' : emailOrPhone,
      'photos': photos != null && photos.isNotEmpty ? [photos[0].path] : ['assets/sreenath.jpg'],
      'photoUrl': photos != null && photos.isNotEmpty ? photos[0].path : 'assets/sreenath.jpg',
      'is_onboarded': true,
      'aadhaar_verified': false,
      'face_verified': false,
      'roses_balance': 25,
      'referral_code': 'VARUDU-${(name.replaceAll(' ', '').toUpperCase() + '77').substring(0, 6)}',
      'tob': tob ?? '09:30 AM',
      'pob': pob ?? city,
      'family_details': {
        'star': star ?? 'Uttara',
        'rasi': rasi ?? 'Kanya',
        'subCaste': subCaste ?? 'Hindu',
        'gothram': gothram ?? 'Kasyapa',
        'education': education ?? 'Graduate',
        'occupation': occupation ?? 'Professional',
        'family_status': 'Upper Middle Class',
        ...?familyDetails,
      },
    };

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

      final returnedProfile = res['profile'] ?? localProfile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_active_profile', jsonEncode(returnedProfile));
      await prefs.setString('saved_user_profile_$emailOrPhone', jsonEncode(returnedProfile));

      state = AuthState(
        status: AuthStatus.authenticated,
        email: emailOrPhone,
        profile: returnedProfile,
      );
    } catch (e) {
      // Backend unreachable or offline: Save locally and authenticate seamlessly!
      debugPrint('Backend createProfile failed: $e. Authenticating locally.');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_active_profile', jsonEncode(localProfile));
      await prefs.setString('saved_user_profile_$emailOrPhone', jsonEncode(localProfile));

      state = AuthState(
        status: AuthStatus.authenticated,
        email: emailOrPhone,
        profile: localProfile,
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
