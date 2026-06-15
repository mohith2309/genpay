import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../services/vault_service.dart';

final transactionBoxProvider = FutureProvider<Box<Transaction>>((ref) async {
  return Hive.openBox<Transaction>(AppConstants.transactionsBox);
});

final transactionsProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>(
  (ref) => TransactionNotifier(),
);

final currentMonthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    data: (txns) {
      final now = DateTime.now();
      // Base list is already sorted by date descending, and .where() preserves order.
      return txns
          .where((t) => t.isApproved && AppUtils.isSameMonth(t.date, now) && !t.isSilent)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final totalSpentProvider = Provider<double>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  return txns.fold(0.0, (sum, t) => sum + t.amount);
});

final spentByCategoryProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  final map = <String, double>{};
  for (final t in txns) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final pendingSmsTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  return txnsAsync.when(
    // Base list is already sorted by date descending, and .where() preserves order.
    data: (txns) => txns.where((t) => t.fromSms && !t.isApproved).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  return txns.take(10).toList();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  Box<Transaction>? _box;
  final _uuid = const Uuid();
  final _vaultService = VaultService();

  TransactionNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox<Transaction>(AppConstants.transactionsBox);
      _loadFromBox();
      _box!.watch().listen((_) => _loadFromBox());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _loadFromBox() {
    if (_box == null) return;
    final txns = _box!.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(txns);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _box?.put(transaction.id, transaction);
    if (transaction.isApproved && !transaction.isSilent && transaction.vaultSaved > 0) {
      await _vaultService.addRoundup(transaction);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _box?.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _box?.delete(id);
  }

  Future<void> toggleSilent(String id) async {
    final txn = _box?.get(id);
    if (txn != null) {
      final updated = txn.copyWith(isSilent: !txn.isSilent);
      await _box?.put(id, updated);
    }
  }

  Future<void> approveTransaction(String id) async {
    final txn = _box?.get(id);
    if (txn != null) {
      final updated = txn.copyWith(isApproved: true);
      await _box?.put(id, updated);
      if (!updated.isSilent && updated.vaultSaved > 0) {
        await _vaultService.addRoundup(updated);
      }
    }
  }

  Future<void> rejectTransaction(String id) async {
    await _box?.delete(id);
  }

  Future<void> approveAll(List<String> ids) async {
    for (final id in ids) {
      await approveTransaction(id);
    }
  }

  Future<void> rejectAll(List<String> ids) async {
    for (final id in ids) {
      await rejectTransaction(id);
    }
  }

  Future<void> addMany(List<Transaction> transactions) async {
    for (final t in transactions) {
      // Don't re-add if already exists (same date + merchant + amount)
      final exists = _box?.values.any((existing) =>
          existing.merchant == t.merchant &&
          existing.amount == t.amount &&
          existing.date.difference(t.date).inMinutes.abs() < 5);
      if (exists != true) {
        await _box?.put(t.id, t);
      }
    }
  }

  Future<Transaction> duplicateTransaction(String id) async {
    final original = _box?.get(id);
    if (original == null) throw Exception('Transaction not found');
    final copy = original.copyWith(
      id: _uuid.v4(),
      date: DateTime.now(),
      fromSms: false,
      isApproved: true,
    );
    await addTransaction(copy);
    return copy;
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }

  /// Stops a recurring subscription: clears the `isRecurring` flag on every
  /// transaction for [merchant], so it drops off the subscriptions list.
  Future<void> cancelRecurring(String merchant) async {
    if (_box == null) return;
    final matches =
        _box!.values.where((t) => t.merchant == merchant && t.isRecurring);
    for (final t in matches) {
      await _box!.put(t.id, t.copyWith(isRecurring: false));
    }
  }
}
