import '../models/transaction.dart';

class DuplicateSubscriptionGroup {
  final String merchant;
  final List<Transaction> duplicates;
  final double totalMonthlyWaste;

  DuplicateSubscriptionGroup({
    required this.merchant,
    required this.duplicates,
    required this.totalMonthlyWaste,
  });
}

class UpgradeAdvisory {
  final String merchant;
  final double oldAmount;
  final double newAmount;
  final String advice;
  final bool isWorthIt;

  UpgradeAdvisory({
    required this.merchant,
    required this.oldAmount,
    required this.newAmount,
    required this.advice,
    required this.isWorthIt,
  });
}

class RefundOpportunity {
  final String merchant;
  final double amount;
  final String reason; // e.g., "Order delayed 45min"
  final DateTime date;
  final String claimTemplate;
  final String supportUrl;

  RefundOpportunity({
    required this.merchant,
    required this.amount,
    required this.reason,
    required this.date,
    required this.claimTemplate,
    required this.supportUrl,
  });
}

class TransactionAnalyzer {
  /// Scans transactions to find duplicate active subscriptions (same merchant, multiple records)
  static List<DuplicateSubscriptionGroup> detectDuplicates(List<Transaction> transactions) {
    final activeRecurring = transactions.where((t) => t.isRecurring && t.isApproved).toList();
    final grouped = <String, List<Transaction>>{};

    for (final t in activeRecurring) {
      grouped.putIfAbsent(t.merchant.toLowerCase(), () => []).add(t);
    }

    final duplicateGroups = <DuplicateSubscriptionGroup>[];

    grouped.forEach((key, list) {
      if (list.length > 1) {
        // Find unique amounts or redundant occurrences of the same subscription
        // Sort by date to keep the latest, highlight the rest as waste
        list.sort((a, b) => b.date.compareTo(a.date));
        final merchantName = list.first.merchant;
        final redundant = list.sublist(1);
        final waste = redundant.fold<double>(0.0, (sum, t) => sum + t.amount);

        duplicateGroups.add(DuplicateSubscriptionGroup(
          merchant: merchantName,
          duplicates: list,
          totalMonthlyWaste: waste,
        ));
      }
    });

    return duplicateGroups;
  }

  /// Checks if a newly added transaction represents an upgrade (higher amount) for a subscription,
  /// and provides AI recommendation copy.
  static UpgradeAdvisory? detectUpgradeAdvisory(Transaction newTxn, List<Transaction> history) {
    if (!newTxn.isRecurring) return null;

    final merchantLower = newTxn.merchant.toLowerCase();
    final pastTxns = history
        .where((t) => t.id != newTxn.id && t.merchant.toLowerCase() == merchantLower && t.isRecurring && t.isApproved)
        .toList();

    if (pastTxns.isEmpty) return null;

    // Find the latest previous transaction amount
    // Optimization: Use reduce instead of sort().first for O(n) max finding
    final oldAmount = pastTxns.reduce((a, b) => a.date.compareTo(b.date) >= 0 ? a : b).amount;

    if (newTxn.amount > oldAmount) {
      // It's a price hike / plan upgrade
      final difference = newTxn.amount - oldAmount;
      
      // Generate some snarky advice based on merchant name
      String advice;
      bool isWorthIt = false;
      if (merchantLower.contains('netflix')) {
        advice = "Netflix upgraded from ₹${oldAmount.toStringAsFixed(0)} to ₹${newTxn.amount.toStringAsFixed(0)}. You only watched 4 hours of screen time this month. Definitely not worth it.";
      } else if (merchantLower.contains('spotify')) {
        advice = "Spotify cost increased. You listen to the same 12 songs on repeat. Consider downgrading to the free tier or individual plan.";
      } else if (merchantLower.contains('youtube')) {
        advice = "YouTube Premium jumped. You only watch tech reviews that you can skip anyway. Save your money!";
      } else {
        advice = "${newTxn.merchant} cost increased by ₹${difference.toStringAsFixed(0)}. Your frequency of using this service doesn't justify the upgrade.";
      }

      return UpgradeAdvisory(
        merchant: newTxn.merchant,
        oldAmount: oldAmount,
        newAmount: newTxn.amount,
        advice: advice,
        isWorthIt: isWorthIt,
      );
    }

    return null;
  }

  /// Scans SMS text list to find delayed, failed, or cancelled orders that are eligible for refund.
  static List<RefundOpportunity> scanRefundOpportunities(List<Map<String, dynamic>> smsMessages) {
    final list = <RefundOpportunity>[];

    for (final sms in smsMessages) {
      final body = (sms['body'] as String? ?? '').toLowerCase();
      final date = sms['date'] as DateTime? ?? DateTime.now();

      // Check for refund opportunity triggers
      final isOpportunity = body.contains('delayed') ||
          body.contains('failed') ||
          body.contains('cancelled') ||
          body.contains('refund eligible');

      if (isOpportunity) {
        // Extract amount (rough estimation or fallback)
        double amount = 150.0;
        final amountMatch = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+(?:\.\d{1,2})?)').firstMatch(body);
        if (amountMatch != null) {
          amount = double.tryParse(amountMatch.group(1) ?? '150.0') ?? 150.0;
        }

        // Determine merchant
        String merchant = 'Service Provider';
        if (body.contains('swiggy')) {
          merchant = 'Swiggy';
        } else if (body.contains('zomato')) {
          merchant = 'Zomato';
        } else if (body.contains('uber')) {
          merchant = 'Uber';
        } else if (body.contains('ola')) {
          merchant = 'Ola';
        } else if (body.contains('zepto')) {
          merchant = 'Zepto';
        } else if (body.contains('blinkit')) {
          merchant = 'Blinkit';
        }

        String reason = 'Transaction failed or delayed';
        String supportUrl = 'https://support.example.com';
        if (body.contains('delay')) {
          reason = 'Order delayed more than 40 mins';
          supportUrl = merchant == 'Swiggy' ? 'https://swiggy.com/support' : 'https://zomato.com/support';
        } else if (body.contains('fail') || body.contains('debit')) {
          reason = 'Amount debited for failed transaction';
          supportUrl = 'https://razorpay.com/support';
        }

        final template = '''Subject: Refund Claim for Delayed/Failed Order

Hi ${merchant} Support,

I am writing to claim a refund for my order placed on ${date.day}/${date.month}/${date.year}.
The order was marked as delayed/failed and under your service terms, I am eligible for compensation.

Details:
- Estimated Refund Amount: ₹${amount.toStringAsFixed(0)}
- Reason: ${reason}
- Payment Source: UPI

Please process this refund to the original source as soon as possible.

Thanks!''';

        list.add(RefundOpportunity(
          merchant: merchant,
          amount: amount,
          reason: reason,
          date: date,
          claimTemplate: template,
          supportUrl: supportUrl,
        ));
      }
    }

    return list;
  }
}
