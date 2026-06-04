import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/payee.dart';
import '../core/constants.dart';

final payeesProvider =
    StateNotifierProvider<PayeeNotifier, List<Payee>>((ref) => PayeeNotifier());

/// The user's own UPI profile (their VPA + display name), used for the
/// "Receive money" QR and as the merchant identity in requests.
final myUpiProfileProvider =
    StateNotifierProvider<MyUpiProfileNotifier, MyUpiProfile>(
        (ref) => MyUpiProfileNotifier());

class MyUpiProfile {
  final String vpa;
  final String name;
  const MyUpiProfile({required this.vpa, required this.name});
}

class MyUpiProfileNotifier extends StateNotifier<MyUpiProfile> {
  MyUpiProfileNotifier()
      : super(const MyUpiProfile(vpa: '', name: 'GenPay User')) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    state = MyUpiProfile(
      vpa: box.get('my_vpa', defaultValue: '') as String,
      name: box.get('my_name', defaultValue: 'GenPay User') as String,
    );
  }

  Future<void> update({String? vpa, String? name}) async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    if (vpa != null) await box.put('my_vpa', vpa.toLowerCase());
    if (name != null) await box.put('my_name', name);
    state = MyUpiProfile(
      vpa: (vpa ?? state.vpa).toLowerCase(),
      name: name ?? state.name,
    );
  }
}

/// Payees sorted by most-recently-paid, for the "People" row.
final recentPayeesProvider = Provider<List<Payee>>((ref) {
  final payees = [...ref.watch(payeesProvider)];
  payees.sort((a, b) {
    final ad = a.lastPaid ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.lastPaid ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });
  return payees;
});

class PayeeNotifier extends StateNotifier<List<Payee>> {
  Box<Payee>? _box;
  final _uuid = const Uuid();

  PayeeNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Payee>(AppConstants.payeesBox);
    _reload();
  }

  void _reload() {
    if (_box == null) return;
    state = _box!.values.toList();
  }

  Payee? byVpa(String vpa) {
    final lower = vpa.toLowerCase();
    for (final p in state) {
      if (p.upiId.toLowerCase() == lower) return p;
    }
    return null;
  }

  /// Adds a payee if new, otherwise returns the existing one.
  Future<Payee> upsert({
    required String name,
    required String upiId,
    String? phone,
  }) async {
    _box ??= await Hive.openBox<Payee>(AppConstants.payeesBox);
    final existing = byVpa(upiId);
    if (existing != null) {
      if (name.isNotEmpty && existing.name != name) {
        final updated = existing.copyWith(name: name, phone: phone);
        await _box!.put(updated.id, updated);
        _reload();
        return updated;
      }
      return existing;
    }
    final colorIdx = state.length % AppConstants.avatarColors.length;
    final payee = Payee(
      id: _uuid.v4(),
      name: name.isEmpty ? upiId.split('@').first : name,
      upiId: upiId.toLowerCase(),
      phone: phone,
      avatarColor: AppConstants.avatarColors[colorIdx],
    );
    await _box!.put(payee.id, payee);
    _reload();
    return payee;
  }

  /// Records a successful payment against a payee (updates totals + recency).
  Future<void> recordPayment(String upiId, double amount) async {
    _box ??= await Hive.openBox<Payee>(AppConstants.payeesBox);
    final payee = byVpa(upiId);
    if (payee == null) return;
    final updated = payee.copyWith(
      lastPaid: DateTime.now(),
      totalPaid: payee.totalPaid + amount,
      payCount: payee.payCount + 1,
    );
    await _box!.put(updated.id, updated);
    _reload();
  }

  Future<void> remove(String id) async {
    await _box?.delete(id);
    _reload();
  }
}
