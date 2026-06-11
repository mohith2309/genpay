import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../models/payee.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payee_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/transaction_card.dart';
import '../transactions/transaction_detail_screen.dart';
import 'scan_qr_screen.dart';
import 'pay_to_upi_screen.dart';
import 'receive_money_screen.dart';
import 'bills_screen.dart';
import 'send_money_screen.dart';
import 'subscriptions_screen.dart';
import 'upi_setup_screen.dart';
import 'bank_accounts_screen.dart';
import 'request_money_screen.dart';

// ── Derived providers ─────────────────────────────────────────────────────────

final upiTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionsProvider).asData?.value ?? [];
  // transactionsProvider is already sorted
  return all.where((t) => t.paymentMethod == 'UPI' && t.isApproved).toList();
});

final upiMonthSpendProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref.watch(upiTransactionsProvider).where((t) {
    return t.date.year == now.year && t.date.month == now.month && !t.isSilent;
  }).fold(0.0, (s, t) => s + t.amount);
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

class UpiScreen extends ConsumerWidget {
  const UpiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupDone = ref.watch(upiSetupDoneProvider);
    if (!setupDone) return const _SetupCta();

    final monthSpend = ref.watch(upiMonthSpendProvider);
    final upiTxns = ref.watch(upiTransactionsProvider);
    final payees = ref.watch(recentPayeesProvider);
    final profile = ref.watch(myUpiProfileProvider);
    final subs = ref.watch(subscriptionsProvider);
    final subsCost = ref.watch(monthlySubscriptionCostProvider);
    final account = ref.watch(primaryAccountProvider);
    final pendingRequests = ref.watch(pendingIncomingProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.electricBlue.withValues(alpha: 0.2),
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _push(context, const BankAccountsScreen()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payments',
                                style: Theme.of(context).textTheme.titleLarge),
                            Row(
                              children: [
                                Text(
                                  account != null
                                      ? '${account.bankName} ${account.maskedAccount}'
                                      : 'UPI',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.neonGreen),
                                ),
                                Icon(Icons.expand_more,
                                    size: 14, color: Theme.of(context).hintColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _push(context, const ScanQrScreen()),
                    ),
                  ],
                ).animate().fadeIn(),
              ),
            ),

            // Pending collect requests
            if (pendingRequests.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: GestureDetector(
                    onTap: () => _push(
                        context, const RequestMoneyScreen(initialTab: 1)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.debit,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${pendingRequests.length} payment request${pendingRequests.length == 1 ? '' : 's'} waiting',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).hintColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Scan & Pay hero — signature indigo→violet gradient CTA.
            // This is the ONE statement element; the rest of the UI stays neutral.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: GestureDetector(
                  onTap: () => _push(context, const ScanQrScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF6366F1), // indigo-500
                          Color(0xFFA855F7), // purple-500
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scan & Pay',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      )),
                              const SizedBox(height: 2),
                              Text('Pay any UPI QR instantly',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.78),
                                      )),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 80.ms),
              ),
            ),

            // Quick actions grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.82,
                  children: [
                    _QuickAction(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan QR',
                      onTap: () => _push(context, const ScanQrScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.alternate_email,
                      label: 'Pay UPI ID',
                      onTap: () => _push(context, const PayToUpiScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.people_outline,
                      label: 'To Contact',
                      onTap: () => _push(context,
                          const PayToUpiScreen(title: 'Pay a contact')),
                    ),
                    _QuickAction(
                      icon: Icons.account_balance_outlined,
                      label: 'To Bank',
                      onTap: () => _push(context,
                          const PayToUpiScreen(title: 'Pay to bank / UPI')),
                    ),
                    _QuickAction(
                      icon: Icons.qr_code_2,
                      label: 'Receive',
                      onTap: () => _push(context, const ReceiveMoneyScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.smartphone,
                      label: 'Recharge',
                      onTap: () => _push(context, const BillsScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pay Bills',
                      onTap: () => _push(context, const BillsScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.swap_horiz,
                      label: 'Self',
                      onTap: () => _selfTransfer(context, profile.vpa),
                    ),
                  ],
                ),
              ),
            ),

            // People row
            if (payees.isNotEmpty)
              SliverToBoxAdapter(
                child: _PeopleRow(payees: payees),
              ),

            // Month summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPI THIS MONTH',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Text(
                        AppUtils.formatCurrency(monthSpend),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text('${upiTxns.length} payments tracked',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),

            // Subscriptions & AutoPay entry
            if (subs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => _push(context, const SubscriptionsScreen()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.softRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🔁',
                                style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Subscriptions & AutoPay',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                                Text(
                                  '${subs.length} active · ${AppUtils.formatCurrency(subsCost)}/mo',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).hintColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Recent transactions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text('RECENT UPI ACTIVITY',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(letterSpacing: 2)),
              ),
            ),

            // Transactions list
            if (upiTxns.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Text('📭', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No UPI payments yet.\nScan a QR or pay a UPI ID.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => TransactionCard(
                      key: ValueKey(upiTxns[i].id),
                      transaction: upiTxns[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(
                              transaction: upiTxns[i]),
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 25).ms),
                    childCount: upiTxns.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _selfTransfer(BuildContext context, String myVpa) {
    if (myVpa.isEmpty) {
      _push(context, const ReceiveMoneyScreen());
      return;
    }
    _push(context, SendMoneyScreen(payeeVpa: myVpa, payeeName: 'Self'));
  }
}

// ── First-time setup CTA (shown until a bank + UPI PIN are set up) ─────────────

class _SetupCta extends StatelessWidget {
  const _SetupCta();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Payments',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              const Text('💸', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text('Set up UPI to start paying',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                'Link your bank account and create a UPI PIN — just like BHIM. Then scan any QR, pay any UPI ID, split bills and recharge.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
              ),
              const SizedBox(height: 24),
              ..._features(context),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpiSetupScreen()),
                  ),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Set up UPI'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _features(BuildContext context) {
    const items = [
      ('🏦', 'Link your bank in seconds'),
      ('🔒', 'Secure 6-digit UPI PIN'),
      ('⚡', 'Pay, scan, split & recharge'),
    ];
    return items
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(e.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 14),
                  Text(e.$2, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ))
        .toList();
  }
}

// ── Quick action tile ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(icon, color: scheme.onSurface, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ── People row ────────────────────────────────────────────────────────────────

class _PeopleRow extends StatelessWidget {
  final List<Payee> payees;
  const _PeopleRow({required this.payees});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('PEOPLE',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: payees.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                if (i == payees.length) {
                  return _PersonAvatar.add(onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PayToUpiScreen()),
                    );
                  });
                }
                final p = payees[i];
                return _PersonAvatar(
                  payee: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendMoneyScreen(
                          payeeVpa: p.upiId, payeeName: p.name),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  final Payee? payee;
  final VoidCallback onTap;
  final bool isAdd;

  const _PersonAvatar({required this.payee, required this.onTap})
      : isAdd = false;
  const _PersonAvatar.add({required this.onTap})
      : payee = null,
        isAdd = true;

  @override
  Widget build(BuildContext context) {
    final color = isAdd ? Theme.of(context).hintColor : Color(payee!.avatarColor);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: isAdd
                  ? Icon(Icons.add, color: Theme.of(context).hintColor)
                  : Text(payee!.initials,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Text(
              isAdd ? 'New' : payee!.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
