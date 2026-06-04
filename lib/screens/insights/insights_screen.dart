import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/insights_provider.dart';
import '../../widgets/trend_graph.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider).maybeWhen(
          data: (d) => d.where((t) => t.isApproved && !t.isSilent).toList(),
          orElse: () => <Transaction>[],
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: txns.isEmpty
            ? const _EmptyInsights()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Text('Your spending DNA 🧬',
                          style: Theme.of(context).textTheme.headlineMedium)
                      .animate()
                      .fadeIn()
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                  _TrendCard(transactions: txns),
                  const SizedBox(height: 16),
                  _ProjectionCard(),
                  const SizedBox(height: 16),
                  _WeekdayCard(),
                  const SizedBox(height: 16),
                  _AiInsightsCard(),
                  const SizedBox(height: 16),
                  _DuplicatesCard(),
                  const SizedBox(height: 16),
                  _MoodCard(),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(letterSpacing: 2)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<Transaction> transactions;
  const _TrendCard({required this.transactions});

  Map<DateTime, double> _buildTrend() {
    final now = DateTime.now();
    final byDay = <DateTime, double>{};
    for (var i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      byDay[day] = 0;
    }
    for (final t in transactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      if (byDay.containsKey(key)) {
        byDay[key] = byDay[key]! + t.amount;
      }
    }
    return byDay;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Last 30 days'),
          TrendGraph(data: _buildTrend()),
        ],
      ),
    );
  }
}

class _ProjectionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(futureProjectionProvider);
    if (p == null) return const SizedBox.shrink();

    final chillTotal = (p.projectedTotal - p.potentialSaving).clamp(0, double.infinity);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Future self'),
          Text('At this rate, you\'ll spend',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(AppUtils.formatCurrency(p.projectedTotal, showDecimals: false),
              style: Theme.of(context).textTheme.displaySmall),
          Text('this month', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VsBox(
                  label: 'You',
                  amount: p.projectedTotal,
                  color: AppColors.debit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VsBox(
                  label: 'You (if you chill)',
                  amount: chillTotal.toDouble(),
                  color: AppColors.credit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.credit.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.suggestion,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VsBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _VsBox({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, fontSize: 11)),
          const SizedBox(height: 6),
          Text(AppUtils.formatAmount(amount),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _WeekdayCard extends ConsumerWidget {
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byDay = ref.watch(dayOfWeekSpendingProvider);
    if (byDay.isEmpty) return const SizedBox.shrink();

    final maxVal = byDay.values.fold(0.0, (a, b) => a > b ? a : b);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Spending by weekday'),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = byDay[i + 1] ?? 0;
                final ratio = maxVal > 0 ? value / maxVal : 0.0;
                final isWeekend = i >= 5;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value > 0 ? AppUtils.formatAmount(value) : '',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 8),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (ratio * 70).clamp(2, 70),
                          decoration: BoxDecoration(
                            color: isWeekend
                                ? AppColors.debit
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_labels[i],
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('AI read on you'),
              const Spacer(),
              insightsAsync.isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const SizedBox.shrink(),
            ],
          ),
          insightsAsync.when(
            loading: () => Text('Crunching your numbers...',
                style: Theme.of(context).textTheme.bodyMedium),
            error: (_, __) => Text('Could not load insights right now.',
                style: Theme.of(context).textTheme.bodyMedium),
            data: (result) {
              final items = [
                ...result.patterns,
                ...result.predictions,
                ...result.tips,
              ].where((s) => s.trim().isNotEmpty).toList();
              if (items.isEmpty) {
                return Text('Add more transactions for sharper insights.',
                    style: Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(color: AppColors.accent)),
                            Expanded(
                              child: Text(s,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                  if (result.biggestWaste.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.debit.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Biggest leak: ${result.biggestWaste}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.debit)),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DuplicatesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupes = ref.watch(duplicateAlertsProvider);
    if (dupes.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Possible double-spends'),
          ...dupes.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Text('🔁 '),
                    Expanded(
                      child: Text(
                        '${d.merchant} · ${d.count}x ${d.period}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(AppUtils.formatCurrency(d.totalAmount, showDecimals: false),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.amber)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MoodCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(moodCorrelationsProvider);
    if (moods.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Mood vs money'),
          ...moods.take(4).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(m.mood, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${m.transactionCount} txns · mostly ${m.topCategory}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Text('avg ${AppUtils.formatAmount(m.averageSpend)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧬', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No data to roast yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Add some transactions and come back.',
                textAlign: TextAlign.center,
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
