import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/constants.dart';
import 'transaction_provider.dart';

/// A recurring payment, derived by grouping `isRecurring` transactions by merchant.
class Subscription {
  final String merchant;
  final String category;
  final double amount;
  final DateTime lastPaid;
  final String? upiId;
  final int count;

  const Subscription({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.lastPaid,
    required this.count,
    this.upiId,
  });

  /// Estimated next debit: one month after the last payment.
  DateTime get nextDue => DateTime(lastPaid.year, lastPaid.month + 1, lastPaid.day);

  int get daysUntilDue => nextDue.difference(DateTime.now()).inDays;
}

final subscriptionsProvider = Provider<List<Subscription>>((ref) {
  final all = ref.watch(transactionsProvider).asData?.value ?? [];
  final recurring = all.where((t) => t.isRecurring && t.isApproved);

  final byMerchant = <String, List<dynamic>>{};
  for (final t in recurring) {
    byMerchant.putIfAbsent(t.merchant, () => []).add(t);
  }

  final subs = <Subscription>[];
  byMerchant.forEach((merchant, txns) {
    // Optimization: No need to re-sort, base transactionsProvider is already sorted descending by date
    final latest = txns.first;
    subs.add(Subscription(
      merchant: merchant,
      category: latest.category,
      amount: latest.amount,
      lastPaid: latest.date,
      upiId: latest.upiId,
      count: txns.length,
    ));
  });

  subs.sort((a, b) => a.nextDue.compareTo(b.nextDue));
  return subs;
});

/// Total monthly cost of all detected subscriptions.
final monthlySubscriptionCostProvider = Provider<double>((ref) {
  return ref
      .watch(subscriptionsProvider)
      .fold(0.0, (sum, s) => sum + s.amount);
});

// ── AutoPay mandates ──────────────────────────────────────────────────────────

/// Set of merchant names the user has enabled UPI AutoPay for.
final autoPayProvider =
    StateNotifierProvider<AutoPayNotifier, Set<String>>((ref) => AutoPayNotifier());

class AutoPayNotifier extends StateNotifier<Set<String>> {
  AutoPayNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    final saved = box.get('autopay_merchants', defaultValue: <dynamic>[]);
    state = Set<String>.from(saved as List);
  }

  bool isOn(String merchant) => state.contains(merchant);

  Future<void> toggle(String merchant) async {
    final next = {...state};
    if (next.contains(merchant)) {
      next.remove(merchant);
    } else {
      next.add(merchant);
    }
    state = next;
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('autopay_merchants', next.toList());
  }

  Future<void> remove(String merchant) async {
    if (!state.contains(merchant)) return;
    final next = {...state}..remove(merchant);
    state = next;
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('autopay_merchants', next.toList());
  }
}
