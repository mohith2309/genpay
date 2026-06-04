import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

final vaultBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(vaultServiceProvider);
  return service.getVaultBalance();
});

final vaultHistoryProvider = FutureProvider<List<VaultEntry>>((ref) async {
  final service = ref.watch(vaultServiceProvider);
  return service.getVaultHistory();
});

final vaultMonthSavingsProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(vaultServiceProvider);
  return service.getTotalSavedThisMonth();
});

class VaultNotifier extends StateNotifier<AsyncValue<double>> {
  final VaultService _service;

  VaultNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final balance = await _service.getVaultBalance();
      state = AsyncValue.data(balance);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<bool> withdraw(double amount, String reason) async {
    final result = await _service.withdraw(amount, reason);
    if (result) await _load();
    return result;
  }

  Future<void> refresh() => _load();
}

final vaultNotifierProvider = StateNotifierProvider<VaultNotifier, AsyncValue<double>>(
  (ref) => VaultNotifier(ref.watch(vaultServiceProvider)),
);
