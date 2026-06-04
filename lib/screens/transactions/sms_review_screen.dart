import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class SmsReviewScreen extends ConsumerWidget {
  const SmsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSmsTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review SMS'),
        actions: [
          if (pending.isNotEmpty)
            TextButton(
              onPressed: () => _rejectAll(context, ref, pending),
              style: TextButton.styleFrom(foregroundColor: AppColors.debit),
              child: const Text('Reject all'),
            ),
        ],
      ),
      body: pending.isEmpty
          ? _EmptyReview()
          : Column(
              children: [
                _Header(count: pending.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: pending.length,
                    itemBuilder: (_, i) => _PendingCard(transaction: pending[i])
                        .animate()
                        .fadeIn(delay: (i * 40).ms)
                        .slideY(begin: 0.1, end: 0),
                  ),
                ),
                _ApproveBar(pending: pending),
              ],
            ),
    );
  }

  void _rejectAll(BuildContext context, WidgetRef ref, List<Transaction> pending) {
    final ids = pending.map((t) => t.id).toList();
    ref.read(transactionsProvider.notifier).rejectAll(ids);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared. Nothing logged.')),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    final msg = AppConstants.foundSmsMessages.first.replaceAll('{count}', '$count');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Text(
        msg,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
      ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  final Transaction transaction;
  const _PendingCard({required this.transaction});

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  late String _category = widget.transaction.category;

  void _approve() {
    HapticFeedback.lightImpact();
    final notifier = ref.read(transactionsProvider.notifier);
    if (_category != widget.transaction.category) {
      notifier.updateTransaction(widget.transaction.copyWith(category: _category));
    }
    notifier.approveTransaction(widget.transaction.id);
  }

  void _reject() {
    HapticFeedback.lightImpact();
    ref.read(transactionsProvider.notifier).rejectTransaction(widget.transaction.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.merchant,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AppUtils.formatCurrency(t.amount),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.debit),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(AppUtils.formatDate(t.date),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 8),
              Text('· ${t.paymentMethod}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _CategoryDropdown(
                value: _category,
                onChanged: (v) => setState(() => _category = v),
              )),
              const SizedBox(width: 10),
              _IconAction(
                icon: Icons.close,
                color: AppColors.debit,
                onTap: _reject,
              ),
              const SizedBox(width: 8),
              _IconAction(
                icon: Icons.check,
                color: AppColors.credit,
                onTap: _approve,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final safeValue =
        AppConstants.defaultCategories.contains(value) ? value : 'Other';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: Icon(Icons.expand_more, color: Theme.of(context).hintColor),
          style: Theme.of(context).textTheme.bodyMedium,
          items: AppConstants.defaultCategories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  Text(AppConstants.categoryIcons[c] ?? '💸'),
                  const SizedBox(width: 8),
                  Text(c),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ApproveBar extends ConsumerWidget {
  final List<Transaction> pending;
  const _ApproveBar({required this.pending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = pending.fold(0.0, (s, t) => s + t.amount);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pending.length} pending',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(AppUtils.formatCurrency(total),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              final ids = pending.map((t) => t.id).toList();
              ref.read(transactionsProvider.notifier).approveAll(ids);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Approved ${ids.length} transactions')),
              );
            },
            icon: const Icon(Icons.done_all),
            label: const Text('Approve all'),
          ),
        ],
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nothing to review',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Inbox zero, financially.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
