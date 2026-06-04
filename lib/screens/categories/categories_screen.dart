import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';
import '../../models/transaction.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/budget_ring.dart';
import '../../widgets/transaction_card.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(currentMonthBudgetsProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final budgetMap = {for (final b in budgets) b.categoryId: b.amount};

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Categories',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final cat = AppConstants.defaultCategories[i];
                    final budget = budgetMap[cat] ??
                        AppConstants.defaultBudgets[cat] ??
                        2000;
                    final used = spent[cat] ?? 0;
                    return _CategoryTile(
                      category: cat,
                      budget: budget,
                      spent: used,
                    ).animate().fadeIn(delay: (i * 40).ms).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                        );
                  },
                  childCount: AppConstants.defaultCategories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final String category;
  final double budget;
  final double spent;

  const _CategoryTile({
    required this.category,
    required this.budget,
    required this.spent,
  });

  double get _pct => budget > 0 ? (spent / budget).clamp(0, 1) : 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(
        int.parse(AppUtils.getCategoryColor(category).replaceAll('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _CategoryDetailScreen(category: category)),
        );
      },
      onLongPress: () => _editBudget(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppConstants.categoryIcons[category] ?? '💸',
                    style: const TextStyle(fontSize: 26)),
                BudgetRing(
                  percentage: _pct.toDouble(),
                  size: 44,
                  strokeWidth: 5,
                  centerText: '${(_pct * 100).toInt()}%',
                ),
              ],
            ),
            const Spacer(),
            Text(category, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              '${AppUtils.formatAmount(spent)} / ${AppUtils.formatAmount(budget)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _editBudget(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    double value = budget.clamp(500, 30000).toDouble();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppConstants.categoryIcons[category] ?? '💸',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text('$category budget',
                          style: Theme.of(ctx).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('₹${value.toInt()}',
                      style: Theme.of(ctx)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: AppColors.accent)),
                  Slider(
                    value: value,
                    min: 500,
                    max: 30000,
                    divisions: 59,
                    activeColor: AppColors.accent,
                    inactiveColor: Theme.of(context).dividerColor,
                    onChanged: (v) => setSheet(() => value = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(budgetProvider.notifier)
                            .setBudget(category, value);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save budget'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryDetailScreen extends ConsumerWidget {
  final String category;
  const _CategoryDetailScreen({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(currentMonthTransactionsProvider);
    final txns = all.where((t) => t.category == category).toList();
    final total = txns.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(AppConstants.categoryIcons[category] ?? '💸'),
            const SizedBox(width: 8),
            Text(category),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent this month',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(AppUtils.formatCurrency(total),
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
                const Spacer(),
                Text('${txns.length} txns',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: txns.isEmpty
                ? Center(
                    child: Text('Nothing here yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: txns
                        .map((Transaction t) =>
                            TransactionCard(key: ValueKey(t.id), transaction: t))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
