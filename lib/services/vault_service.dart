import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/vault_entry.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class VaultService {
  static const String _balanceKey = 'vault_balance';
  static const String _entriesKey = 'vault_entries';
  static const String _withdrawalsKey = 'vault_withdrawals';

  Box? _box;
  final _uuid = const Uuid();

  Future<void> _init() async {
    _box ??= await Hive.openBox(AppConstants.vaultBox);
  }

  Future<double> getVaultBalance() async {
    await _init();
    return (_box!.get(_balanceKey, defaultValue: 0.0) as num).toDouble();
  }

  Future<void> addRoundup(Transaction transaction) async {
    await _init();
    final roundup = AppUtils.calculateRoundup(transaction.amount);
    if (roundup <= 0) return;

    final entry = VaultEntry(
      id: _uuid.v4(),
      amount: roundup,
      transactionId: transaction.id,
      merchant: transaction.merchant,
      date: transaction.date,
    );

    // Update balance
    final currentBalance = await getVaultBalance();
    await _box!.put(_balanceKey, currentBalance + roundup);

    // Add entry
    final entries = await getVaultHistory();
    entries.insert(0, entry);
    // Keep last 100 entries
    final trimmed = entries.take(100).toList();
    await _box!.put(_entriesKey, trimmed.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<List<VaultEntry>> getVaultHistory() async {
    await _init();
    final raw = _box!.get(_entriesKey, defaultValue: <dynamic>[]) as List;
    try {
      return raw.map((e) => VaultEntry.fromJson(jsonDecode(e as String))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> withdraw(double amount, String reason) async {
    await _init();
    final balance = await getVaultBalance();
    if (amount > balance) return false;

    final withdrawal = VaultWithdrawal(
      id: _uuid.v4(),
      amount: amount,
      reason: reason,
      date: DateTime.now(),
    );

    await _box!.put(_balanceKey, balance - amount);

    final withdrawals = await getWithdrawalHistory();
    withdrawals.insert(0, withdrawal);
    final trimmed = withdrawals.take(50).toList();
    await _box!.put(_withdrawalsKey, trimmed.map((e) => jsonEncode(e.toJson())).toList());

    return true;
  }

  Future<List<VaultWithdrawal>> getWithdrawalHistory() async {
    await _init();
    final raw = _box!.get(_withdrawalsKey, defaultValue: <dynamic>[]) as List;
    try {
      return raw.map((e) => VaultWithdrawal.fromJson(jsonDecode(e as String))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<double> getTotalSavedThisMonth() async {
    final entries = await getVaultHistory();
    final now = DateTime.now();
    return entries
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> resetVault() async {
    await _init();
    await _box!.put(_balanceKey, 0.0);
    await _box!.put(_entriesKey, <String>[]);
  }
}
