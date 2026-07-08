import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class BoutiqueState {
  final int roseBalance;
  final String referralCode;
  final List<dynamic> transactions;
  final bool isLoading;
  final String errorMessage;
  final int claimCooldownSeconds; // Seconds remaining for next free claim

  BoutiqueState({
    required this.roseBalance,
    required this.referralCode,
    required this.transactions,
    required this.isLoading,
    required this.errorMessage,
    required this.claimCooldownSeconds,
  });

  factory BoutiqueState.initial() => BoutiqueState(
        roseBalance: 0,
        referralCode: '',
        transactions: [],
        isLoading: false,
        errorMessage: '',
        claimCooldownSeconds: 0,
      );

  BoutiqueState copyWith({
    int? roseBalance,
    String? referralCode,
    List<dynamic>? transactions,
    bool? isLoading,
    String? errorMessage,
    int? claimCooldownSeconds,
  }) {
    return BoutiqueState(
      roseBalance: roseBalance ?? this.roseBalance,
      referralCode: referralCode ?? this.referralCode,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      claimCooldownSeconds: claimCooldownSeconds ?? this.claimCooldownSeconds,
    );
  }
}

class BoutiqueNotifier extends StateNotifier<BoutiqueState> {
  final Ref _ref;

  BoutiqueNotifier(this._ref) : super(BoutiqueState.initial());

  Future<void> fetchBoutiqueData() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      
      // Fetch balance and referral details
      final balanceData = await apiService.getRosesBalance();
      
      // Fetch transaction logs
      final history = await apiService.getRosesHistory();
      
      int cooldown = 0;
      if (balanceData['last_free_rose_at'] != null) {
        final lastClaim = DateTime.parse(balanceData['last_free_rose_at']);
        final nextClaim = lastClaim.add(const Duration(hours: 24));
        final diff = nextClaim.difference(DateTime.now());
        if (diff.inSeconds > 0) {
          cooldown = diff.inSeconds;
        }
      }

      state = state.copyWith(
        roseBalance: balanceData['roses_balance'] ?? 0,
        referralCode: balanceData['referral_code'] ?? '',
        transactions: history,
        claimCooldownSeconds: cooldown,
        isLoading: false,
      );

      // Sync auth profile roses balance
      final authState = _ref.read(authProvider);
      if (authState.profile != null) {
        final updatedUser = Map<String, dynamic>.from(authState.profile!)
          ..['roses_balance'] = balanceData['roses_balance'];
        _ref.read(authProvider.notifier).updateProfile(updatedUser);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Claim Daily Free Rose
  Future<void> claimDailyRose() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      final res = await apiService.claimFreeRose();
      
      state = state.copyWith(
        roseBalance: res['roses_balance'] ?? state.roseBalance,
        claimCooldownSeconds: 24 * 60 * 60, // Start 24 hours countdown
        isLoading: false,
      );

      // Update auth profile balance
      _syncAuthBalance(res['roses_balance']);
      fetchBoutiqueData(); // Refresh history
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // Watch Mock Ad Reward
  Future<void> watchAdReward() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      final res = await apiService.watchAd();
      
      state = state.copyWith(
        roseBalance: res['roses_balance'] ?? state.roseBalance,
        isLoading: false,
      );

      _syncAuthBalance(res['roses_balance']);
      fetchBoutiqueData(); // Refresh history
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // Buy Rose Bundles Order & verify
  Future<void> purchaseRoseBundle(int count, double price) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final apiService = _ref.read(apiServiceProvider);
      
      // Step 1: Create Order
      final order = await apiService.buyRosesOrder(count, price);
      
      // Step 2: Trigger verify immediately for mock flow
      final verification = await apiService.verifyBuyRoses(
        order['id'],
        'pay_mock_' + Math.randomString(),
        count,
      );

      state = state.copyWith(
        roseBalance: verification['roses_balance'] ?? state.roseBalance,
        isLoading: false,
      );

      _syncAuthBalance(verification['roses_balance']);
      fetchBoutiqueData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  void _syncAuthBalance(int? newBalance) {
    if (newBalance == null) return;
    final authState = _ref.read(authProvider);
    if (authState.profile != null) {
      final updatedUser = Map<String, dynamic>.from(authState.profile!)
        ..['roses_balance'] = newBalance;
      _ref.read(authProvider.notifier).updateProfile(updatedUser);
    }
  }

  // Local tick to decrease claim cooldown every second
  void decrementCooldown() {
    if (state.claimCooldownSeconds > 0) {
      state = state.copyWith(claimCooldownSeconds: state.claimCooldownSeconds - 1);
    }
  }
}

class Math {
  static String randomString() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }
}

final boutiqueProvider = StateNotifierProvider<BoutiqueNotifier, BoutiqueState>((ref) {
  return BoutiqueNotifier(ref);
});
