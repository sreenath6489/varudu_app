import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DiscoverState {
  final List<dynamic> profiles;
  final bool isLoading;
  final String errorMessage;

  DiscoverState({
    required this.profiles,
    required this.isLoading,
    required this.errorMessage,
  });

  factory DiscoverState.initial() => DiscoverState(
        profiles: [],
        isLoading: false,
        errorMessage: '',
      );

  DiscoverState copyWith({
    List<dynamic>? profiles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DiscoverState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final Ref _ref;

  DiscoverNotifier(this._ref) : super(DiscoverState.initial());

  Future<void> fetchMatches({String query = ''}) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      final results = await apiService.searchProfiles(query);
      state = state.copyWith(profiles: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Handle Swipe Left or Right (Standard vs Rose)
  Future<Map<String, dynamic>> swipe({
    required String targetId,
    required String status,
    String interactionType = 'standard',
    String? attachedMessage,
  }) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final res = await apiService.swipeProfile(
        receiverId: targetId,
        status: status,
        interactionType: interactionType,
        attachedMessage: attachedMessage,
      );

      // If we swiped successfully, remove the profile from our active stack
      final updatedProfiles = List<dynamic>.from(state.profiles)
        ..removeWhere((p) => p['id'] == targetId);

      state = state.copyWith(profiles: updatedProfiles);

      // If roses were spent, update auth user profile rose balance
      if (interactionType == 'rose' && res['roses_balance'] != null) {
        final authState = _ref.read(authProvider);
        if (authState.profile != null) {
          final updatedUser = Map<String, dynamic>.from(authState.profile!)
            ..['roses_balance'] = res['roses_balance'];
          _ref.read(authProvider.notifier).updateProfile(updatedUser);
        }
      }

      return res;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Helper to remove swiped card without API call (e.g. if we swipe left locally)
  void removeCard(String profileId) {
    final updated = List<dynamic>.from(state.profiles)
      ..removeWhere((p) => p['id'] == profileId);
    state = state.copyWith(profiles: updated);
  }
}

final discoverProvider = StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(ref);
});
