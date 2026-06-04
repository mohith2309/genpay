import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/automation_settings.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../services/transaction_analyzer.dart';
import '../services/razorpay_automation_service.dart';
import 'transaction_provider.dart';

class AutomationState {
  final AutomationSettings settings;
  final List<DuplicateSubscriptionGroup> duplicates;
  final List<RefundOpportunity> refundOpportunities;
  final bool isLoading;

  AutomationState({
    required this.settings,
    this.duplicates = const [],
    this.refundOpportunities = const [],
    this.isLoading = false,
  });

  AutomationState copyWith({
    AutomationSettings? settings,
    List<DuplicateSubscriptionGroup>? duplicates,
    List<RefundOpportunity>? refundOpportunities,
    bool? isLoading,
  }) {
    return AutomationState(
      settings: settings ?? this.settings,
      duplicates: duplicates ?? this.duplicates,
      refundOpportunities: refundOpportunities ?? this.refundOpportunities,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final automationProvider = StateNotifierProvider<AutomationNotifier, AutomationState>((ref) {
  final transactions = ref.watch(transactionsProvider).asData?.value ?? [];
  return AutomationNotifier(transactions);
});

class AutomationNotifier extends StateNotifier<AutomationState> {
  final List<Transaction> _transactions;
  late RazorpayAutomationService _razorpayService;

  AutomationNotifier(this._transactions)
      : super(AutomationState(settings: const AutomationSettings())) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final box = await Hive.openBox(AppConstants.settingsBox);
    
    // Load existing settings if any
    final raw = box.get('automation_settings');
    AutomationSettings settings = const AutomationSettings();
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        settings = AutomationSettings.fromJson(map);
      } catch (_) {}
    }

    // Initialize Razorpay automation service with user keys or default mock keys
    final keyId = box.get('razorpay_key_id', defaultValue: 'rzp_live_testkey_123') as String;
    final keySecret = box.get('razorpay_key_secret', defaultValue: 'secret_123') as String;
    _razorpayService = RazorpayAutomationService(keyId: keyId, keySecret: keySecret);

    state = state.copyWith(
      settings: settings,
      isLoading: false,
    );

    // Initial scans
    await scanForDuplicates();
    await scanForRefundOpportunities();
  }

  Future<void> updateSettings(AutomationSettings newSettings) async {
    state = state.copyWith(settings: newSettings);
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('automation_settings', newSettings.toJson());
    
    if (newSettings.duplicateCancelEnabled) {
      await scanForDuplicates();
    }
    if (newSettings.refundFinderEnabled) {
      await scanForRefundOpportunities();
    }
  }

  Future<void> toggleDuplicateCancel(bool val) async {
    await updateSettings(state.settings.copyWith(duplicateCancelEnabled: val));
  }

  Future<void> toggleUpgradeAdvisory(bool val) async {
    await updateSettings(state.settings.copyWith(upgradeAdvisoryEnabled: val));
  }

  Future<void> toggleSpendingFreeze(bool val) async {
    await updateSettings(state.settings.copyWith(spendingFreezeEnabled: val));
  }

  Future<void> toggleRefundFinder(bool val) async {
    await updateSettings(state.settings.copyWith(refundFinderEnabled: val));
  }

  Future<void> toggleOfflineAi(bool val) async {
    await updateSettings(state.settings.copyWith(offlineAiEnabled: val));
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('privacy_mode', val); // Sync with existing privacy settings
  }

  Future<void> scanForDuplicates() async {
    if (!state.settings.duplicateCancelEnabled) {
      state = state.copyWith(duplicates: []);
      return;
    }
    final dups = TransactionAnalyzer.detectDuplicates(_transactions);
    state = state.copyWith(duplicates: dups);
  }

  Future<void> scanForRefundOpportunities() async {
    if (!state.settings.refundFinderEnabled) {
      state = state.copyWith(refundOpportunities: []);
      return;
    }

    // Mock SMS logs representing transaction notifications to search
    final mockSms = [
      {
        'body': 'Your Swiggy order of Rs. 450 was delayed by 45min. Tap here for refund eligibility.',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'body': 'Transaction of Rs. 1200 on Zomato failed. Amount was debited from your card.',
        'date': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'body': 'Uber ride cancelled. Delay charges of Rs. 60 applied. Claim refund support link https://uber.com/support.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
      }
    ];

    final refunds = TransactionAnalyzer.scanRefundOpportunities(mockSms);
    state = state.copyWith(refundOpportunities: refunds);
  }

  Future<bool> triggerAutoCancel(String subId, String merchant) async {
    state = state.copyWith(isLoading: true);
    final success = await _razorpayService.cancelSubscription(subId);
    state = state.copyWith(isLoading: false);
    
    if (success) {
      // Remove duplicate merchant group locally from the UI
      final list = [...state.duplicates]..removeWhere((g) => g.merchant == merchant);
      state = state.copyWith(duplicates: list);
    }
    return success;
  }
}
