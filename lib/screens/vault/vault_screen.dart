import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';
import '../../models/vault_entry.dart';
import '../../providers/vault_provider.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(vaultBalanceProvider);
    ref.invalidate(vaultHistoryProvider);
    ref.invalidate(vaultMonthSavingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(vaultBalanceProvider);
    final monthAsync = ref.watch(vaultMonthSavingsProvider);
    final historyAsync = ref.watch(vaultHistoryProvider);

    final balance = balanceAsync.asData?.value ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text('Vault 🐷', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Spare change you didn\'t miss',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 28),

            // Balance hero
            Center(
              child: Column(
                children: [
                  Text('VAULT BALANCE',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(letterSpacing: 3)),
                  const SizedBox(height: 8),
                  balanceAsync.when(
                    loading: () => Text('₹—',
                        style: Theme.of(context).textTheme.displayMedium),
                    error: (_, __) => Text('₹0',
                        style: Theme.of(context).textTheme.displayMedium),
                    data: (b) => AnimatedAmountBig(amount: b),
                  ),
                  const SizedBox(height: 8),
                  monthAsync.when(
                    loading: () => const SizedBox(height: 18),
                    error: (_, __) => const SizedBox(height: 18),
                    data: (m) => Text(
                      m > 0
                          ? 'You saved ${AppUtils.formatCurrency(m, showDecimals: false)} this month without thinking'
                          : 'Round-ups land here automatically',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.credit),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.15, end: 0),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: balance > 0
                    ? () => _withdrawSheet(context, ref, balance)
                    : null,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Withdraw'),
              ),
            ),
            const SizedBox(height: 28),

            Text('HOW IT WORKS',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                'Every expense rounds up to the nearest ₹10. A ₹48 coffee quietly drops ₹2 in here. Withdraw anytime.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
              ),
            ),
            const SizedBox(height: 28),

            Text('RECENT ROUND-UPS',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 2)),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
              error: (_, __) => const SizedBox.shrink(),
              data: (entries) => entries.isEmpty
                  ? _EmptyVault()
                  : Column(
                      children: entries
                          .take(20)
                          .map((e) => _RoundupRow(entry: e))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _withdrawSheet(BuildContext context, WidgetRef ref, double balance) {
    HapticFeedback.mediumImpact();
    final amountCtrl = TextEditingController(text: balance.toStringAsFixed(0));
    final reasonCtrl = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdraw from vault',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Available: ${AppUtils.formatCurrency(balance)}',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.credit)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(ctx).textTheme.headlineMedium,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    hintText: 'What for? (optional)',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) {
                        setSheet(() => error = 'Enter a valid amount');
                        return;
                      }
                      if (amount > balance) {
                        setSheet(() => error = 'More than you have saved');
                        return;
                      }
                      final ok = await ref
                          .read(vaultNotifierProvider.notifier)
                          .withdraw(
                              amount,
                              reasonCtrl.text.trim().isEmpty
                                  ? 'Withdrawal'
                                  : reasonCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      _refresh(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Withdrew ${AppUtils.formatCurrency(amount, showDecimals: false)} 💸'
                                : 'Could not withdraw'),
                          ),
                        );
                      }
                    },
                    child: const Text('Confirm withdrawal'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Counts up to a balance using the shared currency formatter.
class AnimatedAmountBig extends StatelessWidget {
  final double amount;
  const AnimatedAmountBig({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          AppUtils.formatCurrency(value, showDecimals: false),
          style: Theme.of(context)
              .textTheme
              .displayMedium
              ?.copyWith(color: AppColors.credit),
        );
      },
    );
  }
}

class _RoundupRow extends StatelessWidget {
  final VaultEntry entry;
  const _RoundupRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.merchant,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(AppUtils.getRelativeDate(entry.date),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('+₹${entry.amount.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.credit)),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Text(
        AppConstants.emptyVault,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}
