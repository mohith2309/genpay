import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payee_provider.dart';
import '../../providers/bank_provider.dart';
import 'payment_status_screen.dart';
import 'upi_pin_screen.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String payeeVpa;
  final String payeeName;
  final double? presetAmount;
  final String? presetNote;

  const SendMoneyScreen({
    super.key,
    required this.payeeVpa,
    required this.payeeName,
    this.presetAmount,
    this.presetNote,
  });

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _uuid = const Uuid();
  final _noteController = TextEditingController();

  String _amount = '';
  String _selectedCategory = 'Other';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    if (widget.presetAmount != null && widget.presetAmount! > 0) {
      _amount = widget.presetAmount!.toStringAsFixed(
          widget.presetAmount! % 1 == 0 ? 0 : 2);
    }
    if (widget.presetNote != null) _noteController.text = widget.presetNote!;
    _selectedCategory = _guessCategory(widget.payeeName);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _guessCategory(String name) {
    final lower = name.toLowerCase();
    for (final entry in AppConstants.merchantCategoryMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'Other';
  }

  double get _amountValue => double.tryParse(_amount) ?? 0;

  void _tapKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '⌫') {
        if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
      } else if (key == '.') {
        if (!_amount.contains('.') && _amount.isNotEmpty) _amount += '.';
      } else {
        // Limit to 2 decimal places
        if (_amount.contains('.')) {
          final decimals = _amount.split('.')[1];
          if (decimals.length >= 2) return;
        }
        if (_amount == '0') {
          _amount = key;
        } else {
          _amount += key;
        }
      }
    });
  }

  Future<void> _pay() async {
    if (_amountValue <= 0) return;
    final account = ref.read(primaryAccountProvider);
    if (account == null) return;

    // Insufficient balance → fail fast with a status screen.
    if (account.balance < _amountValue) {
      _goToStatus(success: false, error: 'Insufficient balance in ${account.bankName}');
      return;
    }

    HapticFeedback.mediumImpact();
    // UPI PIN authorization (NPCI-style).
    final approved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPinScreen(
          title: 'Enter UPI PIN',
          subtitle:
              'to pay ${AppUtils.formatCurrency(_amountValue)} to ${widget.payeeName}',
          account: account,
          onSubmit: (pin) async {
            await Future.delayed(const Duration(milliseconds: 400));
            return ref
                .read(bankAccountsProvider.notifier)
                .verifyPin(account.id, pin);
          },
        ),
      ),
    );

    if (approved != true) return;
    setState(() => _processing = true);

    // Debit the linked account and auto-record the payment.
    await ref.read(bankAccountsProvider.notifier).debit(account.id, _amountValue);
    final txn = Transaction(
      id: _uuid.v4(),
      amount: _amountValue,
      merchant: widget.payeeName,
      category: _selectedCategory,
      date: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      fromSms: false,
      isApproved: true,
      vaultSaved: AppUtils.calculateRoundup(_amountValue),
      paymentMethod: 'UPI',
      upiId: widget.payeeVpa,
      upiApp: 'GenPay',
    );
    await ref.read(transactionsProvider.notifier).addTransaction(txn);
    await ref
        .read(payeesProvider.notifier)
        .upsert(name: widget.payeeName, upiId: widget.payeeVpa);
    await ref
        .read(payeesProvider.notifier)
        .recordPayment(widget.payeeVpa, _amountValue);

    _goToStatus(success: true);
  }

  void _goToStatus({required bool success, String? error}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          success: success,
          amount: _amountValue,
          payeeName: widget.payeeName,
          payeeVpa: widget.payeeVpa,
          paymentId: success
              ? 'GP${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}'
              : null,
          errorMessage: error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
      AppConstants.avatarColors[
          widget.payeeName.hashCode.abs() % AppConstants.avatarColors.length],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Payee chip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(
                  widget.payeeName.isNotEmpty
                      ? widget.payeeName[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.payeeName,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(widget.payeeVpa,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'JetBrains Mono')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Amount display
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('₹',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(color: Theme.of(context).hintColor)),
                      ),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          _amount.isEmpty ? '0' : _amount,
                          key: ValueKey(_amount.isEmpty ? '0' : _amount),
                          style:
                              Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 64,
                                    color: _amount.isEmpty
                                        ? Theme.of(context).hintColor
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Category chip
                  GestureDetector(
                    onTap: _pickCategory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.categoryIcons[_selectedCategory] ?? '💸',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(_selectedCategory,
                              style: Theme.of(context).textTheme.bodySmall),
                          Icon(Icons.expand_more,
                              size: 16, color: Theme.of(context).hintColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Note field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _noteController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Add a note',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.edit_note, size: 20),
              ),
            ),
          ),

          // Keypad
          _Keypad(onKey: _tapKey),

          // Pay button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_amountValue > 0 && !_processing) ? _pay : null,
                child: _processing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary),
                      )
                    : Text(_amountValue > 0
                        ? 'Pay ${AppUtils.formatCurrency(_amountValue)}'
                        : 'Enter amount'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCategory() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.defaultCategories.map((cat) {
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                Navigator.pop(ctx);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : Theme.of(ctx).dividerColor,
                  ),
                ),
                child: Text(
                  '${AppConstants.categoryIcons[cat] ?? '💸'} $cat',
                  style: TextStyle(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  const _Keypad({required this.onKey});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: _keys.map((row) {
          return Row(
            children: row.map((k) {
              return Expanded(
                child: InkWell(
                  onTap: () => onKey(k),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: k == '⌫'
                        ? Icon(Icons.backspace_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 22)
                        : Text(
                            k,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
