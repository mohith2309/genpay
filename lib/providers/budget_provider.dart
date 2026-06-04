import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import 'transaction_provider.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<List<Budget>>>(
  (ref) => BudgetNotifier(),
);

final currentMonthBudgetsProvider = Provider<List<Budget>>((ref) {
  final budgetsAsync = ref.watch(budgetProvider);
  final spentByCategory = ref.watch(spentByCategoryProvider);

  return budgetsAsync.when(
    data: (budgets) {
      final now = DateTime.now();
      return budgets.map((b) {
        final spent = spentByCategory[b.categoryId] ?? 0.0;
        return b.copyWith(spent: spent);
      }).where((b) => AppUtils.isSameMonth(b.month, now)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final totalBudgetProvider = Provider<double>((ref) {
  final budgets = ref.watch(currentMonthBudgetsProvider);
  return budgets.fold(0.0, (sum, b) => sum + b.amount);
});

final overBudgetCategoriesProvider = Provider<List<Budget>>((ref) {
  return ref.watch(currentMonthBudgetsProvider).where((b) => b.isOverBudget).toList();
});

class BudgetNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  Box<Budget>? _box;

  BudgetNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox<Budget>(AppConstants.budgetsBox);
      await _ensureCurrentMonthBudgets();
      _loadFromBox();
      _box!.watch().listen((_) => _loadFromBox());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _loadFromBox() {
    if (_box == null) return;
    state = AsyncValue.data(_box!.values.toList());
  }

  Future<void> _ensureCurrentMonthBudgets() async {
    if (_box == null) return;
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month}';

    final hasCurrentMonth = _box!.values.any(
      (b) => AppUtils.isSameMonth(b.month, now),
    );

    if (!hasCurrentMonth) {
      // Create default budgets for current month
      for (final entry in AppConstants.defaultBudgets.entries) {
        final key = '${entry.key}_$monthStr';
        if (!_box!.containsKey(key)) {
          await _box!.put(
            key,
            Budget(
              categoryId: entry.key,
              amount: entry.value,
              month: DateTime(now.year, now.month, 1),
            ),
          );
        }
      }
    }
  }

  Future<void> setBudget(String category, double amount, {bool isAutopilot = false}) async {
    _box ??= await Hive.openBox<Budget>(AppConstants.budgetsBox);
    final now = DateTime.now();
    final key = '${category}_${now.year}-${now.month}';
    final existing = _box?.get(key);
    if (existing != null) {
      final updated = existing.copyWith(amount: amount, isAutopilot: isAutopilot);
      await _box?.put(key, updated);
    } else {
      await _box?.put(
        key,
        Budget(
          categoryId: category,
          amount: amount,
          month: DateTime(now.year, now.month, 1),
          isAutopilot: isAutopilot,
        ),
      );
    }
  }

  Map<String, double> suggestBudgets(List<Transaction> last3MonthsTxns) {
    final now = DateTime.now();
    final byCategory = <String, List<double>>{};

    for (var monthOffset = 1; monthOffset <= 3; monthOffset++) {
      final month = DateTime(now.year, now.month - monthOffset, 1);
      final monthTxns = last3MonthsTxns.where((t) => AppUtils.isSameMonth(t.date, month));

      final monthByCategory = <String, double>{};
      for (final t in monthTxns) {
        monthByCategory[t.category] = (monthByCategory[t.category] ?? 0) + t.amount;
      }

      for (final entry in monthByCategory.entries) {
        byCategory.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }

    final suggestions = <String, double>{};
    for (final entry in byCategory.entries) {
      final avg = entry.value.fold(0.0, (a, b) => a + b) / entry.value.length;
      // Suggest 10% reduction from average
      suggestions[entry.key] = (avg * 0.9).roundToDouble();
    }

    // Fill in defaults for categories with no history
    for (final cat in AppConstants.defaultCategories) {
      if (!suggestions.containsKey(cat)) {
        suggestions[cat] = AppConstants.defaultBudgets[cat] ?? 2000;
      }
    }

    return suggestions;
  }

  Future<void> applyAutopilotBudgets(List<Transaction> last3MonthsTxns) async {
    final suggestions = suggestBudgets(last3MonthsTxns);
    for (final entry in suggestions.entries) {
      await setBudget(entry.key, entry.value, isAutopilot: true);
    }
  }
}
