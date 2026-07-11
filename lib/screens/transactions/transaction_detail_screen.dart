import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../upi/send_money_screen.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read the latest version from the store so edits reflect live.
    final live = ref
            .watch(transactionsProvider)
            .asData
            ?.value
            .where((t) => t.id == transaction.id)
            .firstOrNull ??
        transaction;

    final t = live;
    final categoryColor =
        Color(int.parse(AppUtils.getCategoryColor(t.category).replaceAll('#', '0xFF')));
    final isUpi = t.paymentMethod == 'UPI';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(editTransaction: t),
              ),
            ),
            tooltip: 'Edit Transaction',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Amount header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppConstants.categoryIcons[t.category] ?? '💸',
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.merchant,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatCurrency(t.amount),
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: AppColors.debit),
                ),
                const SizedBox(height: 8),
                _StatusPill(isPending: !t.isApproved),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Details card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Category',
                  value: t.category,
                  valueColor: categoryColor,
                ),
                _DetailRow(
                    label: 'Date', value: AppUtils.formatDate(t.date)),
                _DetailRow(
                    label: 'Time', value: AppUtils.formatTime(t.date)),
                _DetailRow(label: 'Payment', value: t.paymentMethod),
                if (t.upiApp != null)
                  _DetailRow(label: 'UPI App', value: t.upiApp!),
                if (t.upiId != null)
                  _DetailRow(label: 'UPI ID', value: t.upiId!, mono: true),
                if (t.note != null && t.note!.isNotEmpty)
                  _DetailRow(label: 'Note', value: t.note!),
                if (t.vaultSaved > 0)
                  _DetailRow(
                    label: 'Vault round-up',
                    value: '+${AppUtils.formatCurrency(t.vaultSaved)}',
                    valueColor: AppColors.credit,
                  ),
                _DetailRow(
                  label: 'Source',
                  value: t.fromSms ? 'Auto-detected (SMS)' : 'Added manually',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pay again (UPI only)
          if (isUpi && t.upiId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendMoneyScreen(
                      payeeVpa: t.upiId!,
                      payeeName: t.merchant,
                      presetAmount: t.amount,
                    ),
                  ),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('Pay again'),
              ),
            ),
          const SizedBox(height: 12),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(transactionsProvider.notifier)
                        .toggleSilent(t.id);
                  },
                  icon: Icon(
                      t.isSilent ? Icons.volume_up : Icons.volume_off,
                      size: 18),
                  label: Text(t.isSilent ? 'Unsilence' : 'Silence'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref, t.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.debit,
                    side: const BorderSide(color: AppColors.debit),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete transaction?'),
        content: const Text('This removes it from your history permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionsProvider.notifier).deleteTransaction(id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.debit)),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isPending;
  const _StatusPill({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final color = isPending ? AppColors.amber : AppColors.credit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPending ? Icons.schedule : Icons.check_circle,
              color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            isPending ? 'Pending approval' : 'Completed',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'JetBrains Mono' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
