import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/insight.dart';
import '../services/gemini_service.dart';
import 'transaction_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final insightsProvider = FutureProvider<GeminiInsightResult>((ref) async {
  final txnsAsync = ref.watch(transactionsProvider);
  final gemini = ref.watch(geminiServiceProvider);

  return txnsAsync.when(
    data: (txns) async {
      final now = DateTime.now();
      final recent = txns.where((t) =>
          t.isApproved && t.date.isAfter(now.subtract(const Duration(days: 30)))).toList();
      return gemini.generateInsights(recent);
    },
    loading: () async => GeminiInsightResult(
      patterns: [],
      predictions: [],
      tips: [],
      moodCorrelation: '',
      biggestWaste: '',
    ),
    error: (_, __) async => GeminiInsightResult(
      patterns: [],
      predictions: [],
      tips: [],
      moodCorrelation: '',
      biggestWaste: '',
    ),
  );
});

final futureProjectionProvider = Provider<FutureProjection?>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  if (txns.isEmpty) return null;
  return _calculateProjection(txns);
});

FutureProjection _calculateProjection(List<Transaction> transactions) {
  final today = DateTime.now();
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  final daysPassed = today.day;

  final currentSpend = transactions.fold(0.0, (sum, t) => sum + t.amount);
  final dailyRate = daysPassed > 0 ? currentSpend / daysPassed : 0.0;
  final projectedTotal = dailyRate * daysInMonth;
  final daysRemaining = daysInMonth - daysPassed;

  // Find biggest variable category
  final byCategory = <String, double>{};
  for (final t in transactions) {
    byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
  }

  final sortedCats = (byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  final biggestCategory = sortedCats.isNotEmpty ? sortedCats.first.key : 'Other';
  final biggestAmount = sortedCats.isNotEmpty ? sortedCats.first.value : 0.0;

  // What saving 2x/week on top category would save
  final potentialSaving = biggestAmount * 0.2;

  return FutureProjection(
    currentSpend: currentSpend,
    projectedTotal: projectedTotal,
    dailyRate: dailyRate,
    daysRemaining: daysRemaining,
    biggestCategory: biggestCategory,
    potentialSaving: potentialSaving,
    suggestion:
        'Cut $biggestCategory by 2x/week to save ₹${potentialSaving.toStringAsFixed(0)} this month',
  );
}

final dayOfWeekSpendingProvider = Provider<Map<int, double>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    data: (txns) => _calculateDayOfWeekSpending(txns),
    loading: () => {},
    error: (_, __) => {},
  );
});

Map<int, double> _calculateDayOfWeekSpending(List<Transaction> txns) {
  final approved = txns.where((t) => t.isApproved && !t.isSilent);
  final byDay = <int, List<double>>{};

  for (final t in approved) {
    final day = t.date.weekday;
    byDay.putIfAbsent(day, () => []).add(t.amount);
  }

  final result = <int, double>{};
  for (final entry in byDay.entries) {
    // Average daily spend for that weekday
    result[entry.key] = entry.value.fold(0.0, (a, b) => a + b) / entry.value.length;
  }
  return result;
}

final duplicateAlertsProvider = Provider<List<DuplicateAlert>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    data: (txns) => _detectDuplicates(txns),
    loading: () => [],
    error: (_, __) => [],
  );
});

List<DuplicateAlert> _detectDuplicates(List<Transaction> txns) {
  final now = DateTime.now();
  final thisMonth = txns.where((t) =>
      t.isApproved && t.date.month == now.month && t.date.year == now.year);

  final byMerchant = <String, List<Transaction>>{};
  for (final t in thisMonth) {
    byMerchant.putIfAbsent(t.merchant.toLowerCase(), () => []).add(t);
  }

  final alerts = <DuplicateAlert>[];
  for (final entry in byMerchant.entries) {
    if (entry.value.length >= 2) {
      final total = entry.value.fold(0.0, (s, t) => s + t.amount);
      alerts.add(DuplicateAlert(
        merchant: entry.value.first.merchant,
        count: entry.value.length,
        totalAmount: total,
        period: 'this month',
        dates: entry.value.map((t) => t.date).toList(),
      ));
    }
  }

  alerts.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  return alerts.take(5).toList();
}

final moodCorrelationsProvider = Provider<List<MoodCorrelation>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    data: (txns) => _calculateMoodCorrelations(txns),
    loading: () => [],
    error: (_, __) => [],
  );
});

List<MoodCorrelation> _calculateMoodCorrelations(List<Transaction> txns) {
  final withMood = txns.where((t) => t.mood != null && t.mood!.isNotEmpty && t.isApproved);
  final byMood = <String, List<Transaction>>{};

  for (final t in withMood) {
    byMood.putIfAbsent(t.mood!, () => []).add(t);
  }

  return byMood.entries.map((entry) {
    final avgSpend = entry.value.fold(0.0, (s, t) => s + t.amount) / entry.value.length;
    final catCount = <String, int>{};
    for (final t in entry.value) {
      catCount[t.category] = (catCount[t.category] ?? 0) + 1;
    }
    // ⚡ Bolt: Use O(N) reduce instead of O(N log N) sort to find maximum value
    final topCat = catCount.isNotEmpty ? catCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key : 'Other';

    return MoodCorrelation(
      mood: entry.key,
      averageSpend: avgSpend,
      transactionCount: entry.value.length,
      topCategory: topCat,
    );
  }).toList()
    ..sort((a, b) => b.averageSpend.compareTo(a.averageSpend));
}

final spendingStreakProvider = Provider<int>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    data: (txns) => _calculateStreak(txns),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

int _calculateStreak(List<Transaction> txns) {
  // Count consecutive days under budget (simplified: days with < ₹1000 total)
  if (txns.isEmpty) return 0;
  final byDay = <String, double>{};
  for (final t in txns.where((t) => t.isApproved && !t.isSilent)) {
    final key = t.date.toIso8601String().substring(0, 10);
    byDay[key] = (byDay[key] ?? 0) + t.amount;
  }

  int streak = 0;
  final now = DateTime.now();
  for (var i = 0; i < 30; i++) {
    final day = now.subtract(Duration(days: i));
    final key = day.toIso8601String().substring(0, 10);
    final daySpend = byDay[key] ?? 0;
    if (daySpend < 1000) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
