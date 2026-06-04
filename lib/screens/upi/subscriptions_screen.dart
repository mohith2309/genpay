import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_provider.dart';
import 'send_money_screen.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionsProvider);
    final monthlyCost = ref.watch(monthlySubscriptionCostProvider);
    final autoPay = ref.watch(autoPayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions & AutoPay')),
      body: subs.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.softRed.withValues(alpha: 0.2),
                      AppColors.softRed.withValues(alpha: 0.05),
                    ]),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.softRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RECURRING EVERY MONTH',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text(
                              AppUtils.formatCurrency(monthlyCost),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontFamily: 'JetBrains Mono'),
                            ),
                            Text(
                              '${subs.length} subscription${subs.length == 1 ? '' : 's'} · ${autoPay.length} on AutoPay',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Text('🔁', style: TextStyle(fontSize: 34)),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    "That's ${AppUtils.formatCurrency(monthlyCost * 12)} a year. Cancel what you don't use.",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ),
                const SizedBox(height: 8),

                ...subs.asMap().entries.map((e) {
                  final sub = e.value;
                  return _SubscriptionTile(
                    sub: sub,
                    autoPayOn: autoPay.contains(sub.merchant),
                    onToggleAutoPay: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(autoPayProvider.notifier)
                          .toggle(sub.merchant);
                    },
                    onTap: () => _showActions(context, ref, sub),
                  ).animate().fadeIn(delay: (e.key * 50).ms);
                }),
              ],
            ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, Subscription sub) {
    final autoPayOn = ref.read(autoPayProvider).contains(sub.merchant);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(sub.merchant, style: Theme.of(ctx).textTheme.titleLarge),
            Text(
              '${AppUtils.formatCurrency(sub.amount)} / month',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (sub.upiId != null)
              ListTile(
                leading: const Icon(Icons.send, color: AppColors.electricBlue),
                title: const Text('Pay now'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendMoneyScreen(
                        payeeVpa: sub.upiId!,
                        payeeName: sub.merchant,
                        presetAmount: sub.amount,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(
                autoPayOn ? Icons.toggle_on : Icons.toggle_off,
                color: autoPayOn ? AppColors.neonGreen : Theme.of(context).hintColor,
              ),
              title: Text(autoPayOn ? 'Turn off AutoPay' : 'Set up AutoPay'),
              subtitle: Text(
                autoPayOn
                    ? 'Auto-debit is on for this subscription'
                    : 'Auto-debit ${AppUtils.formatCurrency(sub.amount)} each month',
              ),
              onTap: () {
                ref.read(autoPayProvider.notifier).toggle(sub.merchant);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined,
                  color: AppColors.softRed),
              title: const Text('Cancel subscription',
                  style: TextStyle(color: AppColors.softRed)),
              onTap: () {
                ref.read(autoPayProvider.notifier).remove(sub.merchant);
                ref
                    .read(transactionsProvider.notifier)
                    .cancelRecurring(sub.merchant);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${sub.merchant} unsubscribed')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Subscription sub;
  final bool autoPayOn;
  final VoidCallback onToggleAutoPay;
  final VoidCallback onTap;

  const _SubscriptionTile({
    required this.sub,
    required this.autoPayOn,
    required this.onToggleAutoPay,
    required this.onTap,
  });

  String get _dueText {
    final d = sub.daysUntilDue;
    if (d < 0) return 'Due now';
    if (d == 0) return 'Due today';
    if (d == 1) return 'Due tomorrow';
    return 'Due in $d days';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
        int.parse(AppUtils.getCategoryColor(sub.category).replaceAll('#', '0xFF')));
    final dueSoon = sub.daysUntilDue <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(AppConstants.categoryIcons[sub.category] ?? '🔁',
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.merchant,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _dueText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: dueSoon
                                  ? AppColors.warningAmber
                                  : Theme.of(context).hintColor,
                            ),
                      ),
                      if (autoPayOn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('AutoPay',
                              style: TextStyle(
                                  color: AppColors.neonGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppUtils.formatCurrency(sub.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                      ),
                ),
                Text('/mo',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No subscriptions detected yet.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Mark a payment as "Recurring" when adding it, and it\'ll show up here so you can manage AutoPay and cancel anytime.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
