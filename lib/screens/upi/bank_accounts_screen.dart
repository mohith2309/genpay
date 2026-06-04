import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/bank_account.dart';
import '../../providers/bank_provider.dart';
import 'upi_pin_screen.dart';
import 'upi_setup_screen.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(bankAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank accounts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...accounts.map((a) => _AccountCard(account: a)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpiSetupScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add another bank account'),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  final BankAccount account;
  const _AccountCard({required this.account});

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _balanceVisible = false;

  Future<void> _checkBalance() async {
    final a = widget.account;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPinScreen(
          title: 'Enter UPI PIN',
          subtitle: 'to check your ${a.bankName} balance',
          account: a,
          onSubmit: (pin) async {
            await Future.delayed(const Duration(milliseconds: 400));
            return ref.read(bankAccountsProvider.notifier).verifyPin(a.id, pin);
          },
        ),
      ),
    );
    if (ok == true && mounted) setState(() => _balanceVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final color = Color(a.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.account_balance, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.bankName,
                            style: Theme.of(context).textTheme.titleSmall),
                        if (a.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('PRIMARY',
                                style: TextStyle(
                                    color: AppColors.neonGreen,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(a.maskedAccount,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontFamily: 'JetBrains Mono')),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: Theme.of(context).colorScheme.surface,
                icon: Icon(Icons.more_vert, color: Theme.of(context).hintColor),
                onSelected: (v) {
                  if (v == 'primary') {
                    ref.read(bankAccountsProvider.notifier).setPrimary(a.id);
                  } else if (v == 'remove') {
                    ref.read(bankAccountsProvider.notifier).remove(a.id);
                  }
                },
                itemBuilder: (_) => [
                  if (!a.isPrimary)
                    const PopupMenuItem(
                        value: 'primary', child: Text('Set as primary')),
                  const PopupMenuItem(
                      value: 'remove', child: Text('Remove account')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(a.vpa,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'JetBrains Mono', color: color)),
          const SizedBox(height: 14),
          // Balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BALANCE',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(
                    _balanceVisible
                        ? AppUtils.formatCurrency(a.balance)
                        : '••••••',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'JetBrains Mono',
                        ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _balanceVisible
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _balanceVisible = false);
                      }
                    : _checkBalance,
                icon: Icon(
                    _balanceVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16),
                label: Text(_balanceVisible ? 'Hide' : 'Check balance'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
