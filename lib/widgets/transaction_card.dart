import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';

class TransactionCard extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showSwipeActions;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showSwipeActions = true,
  });

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  double _dragOffset = 0;
  bool _isRevealing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onDelete() {
    HapticFeedback.mediumImpact();
    ref
        .read(transactionsProvider.notifier)
        .deleteTransaction(widget.transaction.id);
  }

  void _onSilent() {
    HapticFeedback.selectionClick();
    ref.read(transactionsProvider.notifier).toggleSilent(widget.transaction.id);
    setState(() {
      _dragOffset = 0;
    });
  }

  void _onRepeat() {
    HapticFeedback.mediumImpact();
    ref
        .read(transactionsProvider.notifier)
        .duplicateTransaction(widget.transaction.id);
    setState(() {
      _dragOffset = 0;
    });
  }

  Color get _amountColor {
    if (widget.transaction.isSilent) return AppColors.mutedText;
    if (widget.transaction.isEmotionalSpend) return AppColors.softRed;
    return AppColors.softRed;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final categoryColor = AppUtils.getCategoryColor(t.category);
    final color = Color(int.parse(categoryColor.replaceAll('#', '0xFF')));

    return GestureDetector(
      onHorizontalDragUpdate: widget.showSwipeActions
          ? (details) {
              setState(() {
                _dragOffset =
                    (_dragOffset + details.delta.dx).clamp(-160.0, 80.0);
                _isRevealing = true;
              });
            }
          : null,
      onHorizontalDragEnd: widget.showSwipeActions
          ? (details) {
              if (_dragOffset < -80) {
                HapticFeedback.lightImpact();
                setState(() => _dragOffset = -160);
              } else if (_dragOffset > 40) {
                HapticFeedback.lightImpact();
                setState(() => _dragOffset = 80);
              } else {
                setState(() {
                  _dragOffset = 0;
                  _isRevealing = false;
                });
              }
            }
          : null,
      onTap: () {
        if (_dragOffset != 0) {
          setState(() {
            _dragOffset = 0;
            _isRevealing = false;
          });
        } else {
          widget.onTap?.call();
        }
      },
      child: Stack(
        children: [
          // Background action buttons
          if (_isRevealing || _dragOffset != 0) ...[
            // Left actions (swipe left reveals): Delete + Silent
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.volume_off,
                    label: t.isSilent ? 'Unsilent' : 'Silent',
                    color: AppColors.electricBlue,
                    onTap: _onSilent,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.softRed,
                    onTap: _onDelete,
                  ),
                ],
              ),
            ),
            // Right action (swipe right reveals): Repeat
            Positioned.fill(
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.repeat,
                    label: 'Repeat',
                    color: AppColors.neonGreen,
                    onTap: _onRepeat,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
          // Card content
          Semantics(
            customSemanticsActions: {
              const CustomSemanticsAction(label: 'Delete'): _onDelete,
              CustomSemanticsAction(label: t.isSilent ? 'Unsilent' : 'Silent'):
                  _onSilent,
              const CustomSemanticsAction(label: 'Repeat'): _onRepeat,
            },
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: t.isEmotionalSpend
                        ? AppColors.softRed.withValues(alpha: 0.3)
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppConstants.categoryIcons[t.category] ?? '💸',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.merchant,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (t.isSilent)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text('🔇',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              if (t.isEmotionalSpend)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.softRed
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'impulse',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.softRed,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                t.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: color,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppUtils.getRelativeDate(t.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (t.upiApp != null) ...[
                                const SizedBox(width: 6),
                                _UpiAppChip(app: t.upiApp!),
                              ] else if (t.paymentMethod == 'UPI') ...[
                                const SizedBox(width: 6),
                                _UpiAppChip(app: 'UPI'),
                              ],
                              if (t.mood != null) ...[
                                const SizedBox(width: 4),
                                Text(t.mood!,
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ],
                          ),
                          if (t.upiId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                t.upiId!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 10,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppUtils.formatCurrency(t.amount),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: _amountColor,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                        ),
                        if (t.vaultSaved > 0)
                          Text(
                            '+₹${t.vaultSaved.toStringAsFixed(0)} vault',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.neonGreen,
                                  fontSize: 9,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpiAppChip extends StatelessWidget {
  final String app;
  const _UpiAppChip({required this.app});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.upiAppEmojis[app] ?? '💳';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: AppColors.electricBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 2),
          Text(
            app,
            style: const TextStyle(
              color: AppColors.electricBlue,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
