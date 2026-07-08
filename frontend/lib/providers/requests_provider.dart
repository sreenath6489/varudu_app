import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class RequestsState {
  final List<dynamic> received;
  final List<dynamic> sent;
  final bool isLoading;
  final String errorMessage;

  RequestsState({
    required this.received,
    required this.sent,
    required this.isLoading,
    required this.errorMessage,
  });

  factory RequestsState.initial() => RequestsState(
        received: [],
        sent: [],
        isLoading: false,
        errorMessage: '',
      );

  RequestsState copyWith({
    List<dynamic>? received,
    List<dynamic>? sent,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RequestsState(
      received: received ?? this.received,
      sent: sent ?? this.sent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RequestsNotifier extends StateNotifier<RequestsState> {
  final Ref _ref;

  RequestsNotifier(this._ref) : super(RequestsState.initial());

  Future<void> fetchRequests() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      final data = await apiService.getRequests();
      
      state = state.copyWith(
        received: data['received'] ?? [],
        sent: data['sent'] ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> accept(String interestId) async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.acceptInterest(interestId);
      state = state.copyWith(isLoading: false);
      fetchRequests(); // Refresh lists
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> decline(String interestId) async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.declineInterest(interestId);
      state = state.copyWith(isLoading: false);
      fetchRequests(); // Refresh lists
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> withdraw(String interestId) async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.withdrawInterest(interestId);
      state = state.copyWith(isLoading: false);
      fetchRequests(); // Refresh lists
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final requestsProvider = StateNotifierProvider<RequestsNotifier, RequestsState>((ref) {
  return RequestsNotifier(ref);
});
