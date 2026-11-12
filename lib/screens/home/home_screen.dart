import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/pause_mode_provider.dart';
import '../../services/sms_parser_service.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/animated_amount.dart';
import '../../widgets/budget_ring.dart';
import '../../widgets/pause_mode_overlay.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/sms_review_screen.dart';
import '../transactions/transaction_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _smsParser = SmsParserService();
  bool _isScanning = false;

  Future<void> _scanSms() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    final transactions = await _smsParser.fetchAndParseUpiSms();
    if (transactions.isNotEmpty) {
      await ref.read(transactionsProvider.notifier).addMany(transactions);
    }

    setState(() => _isScanning = false);

    final pending = ref.read(pendingSmsTransactionsProvider);
    if (pending.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmsReviewScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactions.isEmpty
                ? 'No new UPI transactions found'
                : '${transactions.length} transactions found. Review them!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = ref.watch(totalSpentProvider);
    final totalBudget = ref.watch(totalBudgetProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final budgets = ref.watch(currentMonthBudgetsProvider);
    final pendingCount = ref.watch(pendingSmsTransactionsProvider).length;
    final pauseState = ref.watch(pauseModeProvider);

    final budgetPct = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    return PauseModeOverlay(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _scanSms,
          color: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                title: Row(
                  children: [
                    Text(
                      'GenPay',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (_isScanning)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
                actions: [
                  if (pendingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Badge(
                        label: Text('$pendingCount'),
                        backgroundColor: AppColors.softRed,
                        child: IconButton(
                          icon: const Icon(Icons.sms_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SmsReviewScreen()),
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _scanSms,
                    tooltip: 'Scan SMS',
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header
                      Text(
                        AppUtils.formatMonthYear(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                              letterSpacing: 2,
                            ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),

                      // Main amount — neutral hero (color comes from text theme)
                      AnimatedAmount(
                        amount: totalSpent,
                        style: Theme.of(context).textTheme.displayLarge,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 4),
                      Text(
                        'of ${AppUtils.formatCurrency(totalBudget)} budget',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 24),

                      // Overall budget bar
                      _OverallBudgetBar(percentage: budgetPct.toDouble()),

                      const SizedBox(height: 24),

                      // Pause mode banner
                      if (pauseState.isPaused) ...[
                        _PauseModeBanner(remainingText: pauseState.remainingText),
                        const SizedBox(height: 16),
                      ],

                      // Category quick cards
                      Text(
                        'CATEGORIES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _CategoryCards(budgets: budgets),

                      const SizedBox(height: 28),

                      // Recent transactions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECENT',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.electricBlue,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (recentTxns.isEmpty)
                        _EmptyTransactions()
                      else
                        ...recentTxns.asMap().entries.map((entry) {
                          return TransactionCard(
                            key: ValueKey(entry.value.id),
                            transaction: entry.value,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                    transaction: entry.value),
                              ),
                            ),
                          ).animate().fadeIn(
                                delay: (entry.key * 50).ms,
                                duration: 400.ms,
                              );
                        }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ),
          tooltip: 'Add Transaction',
          child: const Icon(Icons.add, size: 28),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}

class _OverallBudgetBar extends StatefulWidget {
  final double percentage;
  const _OverallBudgetBar({required this.percentage});

  @override
  State<_OverallBudgetBar> createState() => _OverallBudgetBarState();
}

class _OverallBudgetBarState extends State<_OverallBudgetBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage.clamp(0, 1)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_OverallBudgetBar old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage.clamp(0, 1),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _barColor {
    final p = widget.percentage;
    if (p < 0.6) return AppColors.neonGreen;
    if (p < 0.8) return AppColors.warningAmber;
    if (p < 1.0) return const Color(0xFFFF9933);
    return AppColors.softRed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(color: Theme.of(context).dividerColor),
                        Container(
                          width: constraints.maxWidth * _animation.value,
                          color: _barColor,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_animation.value * 100).toStringAsFixed(0)}% used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _barColor,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCards extends StatelessWidget {
  final List budgets;
  const _CategoryCards({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final showCats = ['Food', 'Transport', 'Shopping', 'Bills'];
    final filtered = budgets.where((b) => showCats.contains(b.categoryId)).toList();

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filtered.asMap().entries.map((entry) {
          final b = entry.value;
          final color = Color(
            int.parse(AppUtils.getCategoryColor(b.categoryId).replaceAll('#', '0xFF')),
          );
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.categoryIcons[b.categoryId] ?? '💸',
                      style: const TextStyle(fontSize: 20),
                    ),
                    BudgetRing(
                      percentage: b.percentage,
                      size: 36,
                      strokeWidth: 4,
                      centerText: '${(b.percentage * 100).toInt()}%',
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  b.categoryId,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                Text(
                  AppUtils.formatAmount(b.spent),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (entry.key * 80).ms).slideX(begin: 0.2, end: 0);
        }).toList(),
      ),
    );
  }
}

class _PauseModeBanner extends StatelessWidget {
  final String remainingText;
  const _PauseModeBanner({required this.remainingText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🧊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooling period active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.electricBlue,
                      ),
                ),
                Text(
                  remainingText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            AppConstants.emptyStateMessages.first,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
