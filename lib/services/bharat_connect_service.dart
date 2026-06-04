import 'dart:math';
import '../core/billers.dart';

/// A bill returned by a Bharat Connect (BBPS) fetch.
class FetchedBill {
  final String billerName;
  final String consumerNumber;
  final String customerName;
  final double amount;
  final DateTime billDate;
  final DateTime dueDate;
  final String billNumber;

  const FetchedBill({
    required this.billerName,
    required this.consumerNumber,
    required this.customerName,
    required this.amount,
    required this.billDate,
    required this.dueDate,
    required this.billNumber,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now());
}

/// A prepaid mobile recharge plan.
class RechargePlan {
  final double amount;
  final String validity;
  final String benefit;

  const RechargePlan(this.amount, this.validity, this.benefit);
}

/// Simulates Bharat Connect bill presentment. A real integration calls a
/// registered BBPS agent API; here we generate a stable, plausible bill from
/// the consumer reference so the fetch → pay flow is fully demoable. Actual
/// settlement is handled by [RazorpayService].
class BharatConnectService {
  /// Deterministic fetch: the same biller + consumer number always returns the
  /// same bill, so re-fetching is consistent within a session.
  static Future<FetchedBill> fetchBill({
    required Biller biller,
    required BillerCategory category,
    required String consumerNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900)); // network feel

    final seed = (biller.id + consumerNumber).hashCode;
    final rng = Random(seed);

    final range = _amountRange(category.key);
    final amount = (range.$1 + rng.nextInt(range.$2 - range.$1)).toDouble();

    final now = DateTime.now();
    final billDate = now.subtract(Duration(days: 8 + rng.nextInt(6)));
    final dueDate = billDate.add(const Duration(days: 20));

    return FetchedBill(
      billerName: biller.name,
      consumerNumber: consumerNumber,
      customerName: _maskedName(seed),
      amount: amount,
      billDate: billDate,
      dueDate: dueDate,
      billNumber: 'BBPS${(seed.abs() % 9000000 + 1000000)}',
    );
  }

  static (int, int) _amountRange(String categoryKey) {
    switch (categoryKey) {
      case 'electricity':
        return (450, 3200);
      case 'water':
        return (180, 900);
      case 'gas':
        return (350, 1400);
      case 'lpg':
        return (805, 1110);
      case 'broadband':
        return (499, 1499);
      case 'dth':
        return (250, 600);
      case 'creditcard':
        return (1200, 28000);
      case 'insurance':
        return (1800, 12000);
      case 'fastag':
        return (200, 1000);
      case 'loan':
        return (2500, 18000);
      case 'education':
        return (5000, 45000);
      default:
        return (200, 2000);
    }
  }

  static String _maskedName(int seed) {
    const names = [
      'R***** S*****',
      'A**** K*****',
      'P***** M*****',
      'S***** R**',
      'V***** N*****',
      'M***** I*****',
    ];
    return names[seed.abs() % names.length];
  }

  static const List<RechargePlan> rechargePlans = [
    RechargePlan(199, '28 days', '1.5GB/day · Unlimited calls · 100 SMS/day'),
    RechargePlan(299, '28 days', '2GB/day · Unlimited calls · 100 SMS/day'),
    RechargePlan(479, '56 days', '1.5GB/day · Unlimited calls · 100 SMS/day'),
    RechargePlan(666, '84 days', '1.5GB/day · Unlimited calls · 100 SMS/day'),
    RechargePlan(719, '84 days', '2GB/day · Unlimited calls · Disney+ Hotstar'),
    RechargePlan(3599, '365 days', '2.5GB/day · Unlimited calls · 100 SMS/day'),
  ];
}
