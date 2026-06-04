import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/bank_account.dart';
import '../core/constants.dart';

final bankAccountsProvider =
    StateNotifierProvider<BankNotifier, List<BankAccount>>(
        (ref) => BankNotifier());

/// The primary linked account (used by default for payments), or null.
final primaryAccountProvider = Provider<BankAccount?>((ref) {
  final accounts = ref.watch(bankAccountsProvider);
  for (final a in accounts) {
    if (a.isPrimary) return a;
  }
  return accounts.isNotEmpty ? accounts.first : null;
});

/// Whether the user has completed UPI first-time setup (a linked account with
/// a UPI PIN). Gates the payment flows, like BHIM.
final upiSetupDoneProvider = Provider<bool>((ref) {
  final primary = ref.watch(primaryAccountProvider);
  return primary != null && primary.hasPin;
});

class BankNotifier extends StateNotifier<List<BankAccount>> {
  Box<BankAccount>? _box;
  final _uuid = const Uuid();

  BankNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<BankAccount>(AppConstants.bankAccountsBox);
    _reload();
  }

  void _reload() {
    if (_box == null) return;
    state = _box!.values.toList();
  }

  /// Links a new account. Generates a plausible masked number, a seeded
  /// opening balance, and the user's VPA from their phone + bank handle.
  Future<BankAccount> linkAccount({
    required String bankName,
    required String handle,
    required String ifscPrefix,
    required String phone,
    double? openingBalance,
  }) async {
    _box ??= await Hive.openBox<BankAccount>(AppConstants.bankAccountsBox);
    final seed = (bankName + phone).hashCode.abs();
    final last4 = (seed % 9000 + 1000).toString();
    final balance = openingBalance ?? (15000 + (seed % 85000)).toDouble();
    final colorIdx = state.length % AppConstants.avatarColors.length;

    final account = BankAccount(
      id: _uuid.v4(),
      bankName: bankName,
      accountLast4: last4,
      ifsc: '${ifscPrefix}0${seed % 900000 + 100000}',
      balance: balance,
      vpa: '$phone@$handle',
      isPrimary: state.isEmpty,
      colorValue: AppConstants.avatarColors[colorIdx],
    );
    await _box!.put(account.id, account);
    _reload();
    return account;
  }

  Future<void> setUpiPin(String accountId, String pin) async {
    final acct = _box?.get(accountId);
    if (acct == null) return;
    await _box!.put(accountId, acct.copyWith(upiPin: pin));
    _reload();
  }

  Future<void> setPrimary(String accountId) async {
    if (_box == null) return;
    for (final a in _box!.values) {
      await _box!.put(a.id, a.copyWith(isPrimary: a.id == accountId));
    }
    _reload();
  }

  bool verifyPin(String accountId, String pin) {
    final acct = _box?.get(accountId);
    return acct != null && acct.upiPin == pin;
  }

  /// Debits the account after a successful UPI PIN auth. Returns false if the
  /// balance is insufficient.
  Future<bool> debit(String accountId, double amount) async {
    final acct = _box?.get(accountId);
    if (acct == null || acct.balance < amount) return false;
    await _box!.put(accountId, acct.copyWith(balance: acct.balance - amount));
    _reload();
    return true;
  }

  Future<void> credit(String accountId, double amount) async {
    final acct = _box?.get(accountId);
    if (acct == null) return;
    await _box!.put(accountId, acct.copyWith(balance: acct.balance + amount));
    _reload();
  }

  Future<void> remove(String accountId) async {
    await _box?.delete(accountId);
    _reload();
  }
}
