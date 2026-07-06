import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/automation_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/freeze_manager.dart';
import '../../services/transaction_analyzer.dart';
import '../../widgets/mood_picker.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? editTransaction;

  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'UPI';
  String? _selectedUpiApp;
  String? _selectedMood;
  bool _isSilent = false;
  bool _isRecurring = false;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final t = widget.editTransaction;
    if (t != null) {
      _merchantController.text = t.merchant;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _upiIdController.text = t.upiId ?? '';
      _selectedCategory = t.category;
      _selectedPaymentMethod = t.paymentMethod;
      _selectedUpiApp = t.upiApp;
      _selectedMood = t.mood;
      _isSilent = t.isSilent;
      _isRecurring = t.isRecurring;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _autoDetectCategory() {
    final merchant = _merchantController.text.toLowerCase();
    for (final entry in AppConstants.merchantCategoryMap.entries) {
      if (merchant.contains(entry.key)) {
        setState(() => _selectedCategory = entry.value);
        return;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<bool> _checkSpendingFreeze(double amount) async {
    final fm = FreezeManager();
    final isFreezeActive = await fm.isFreezeActive();
    final autoSettings = ref.read(automationProvider).settings;

    if (autoSettings.spendingFreezeEnabled && isFreezeActive) {
      final overrideSuccess = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _EmergencyOverrideDialog(),
      );
      return overrideSuccess ?? false;
    }

    // Check if this transaction pushes spent above 90% budget
    final totalSpent = ref.read(totalSpentProvider);
    final totalBudget = ref.read(totalBudgetProvider);
    if (totalBudget > 0 && !autoSettings.spendingFreezeEnabled) {
      final newSpentPct = (totalSpent + amount) / totalBudget;
      if (newSpentPct >= 0.90) {
        final enable = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('🧊 Budget Alert: 90% Hit!'),
            content: const Text(
              'Your total spending has reached or exceeded 90% of your budget. Would you like to enable a Spending Freeze to auto-block all new transactions for the next 24 hours?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('No, thanks', style: TextStyle(color: Theme.of(context).hintColor)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enable Freeze'),
              ),
            ],
          ),
        );

        if (enable == true) {
          await ref.read(automationProvider.notifier).toggleSpendingFreeze(true);
          await fm.activateFreeze();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🧊 Spending Freeze activated for 24 hours.')),
            );
          }
          return false; // Cancel adding this transaction, freeze is active now!
        }
      }
    }

    return true; // No freeze active, or override accepted
  }

  Future<bool> _checkUpgradeAdvisory(Transaction txn) async {
    final autoSettings = ref.read(automationProvider).settings;
    if (!autoSettings.upgradeAdvisoryEnabled) return true;

    final history = ref.read(transactionsProvider).asData?.value ?? [];
    final advisory = TransactionAnalyzer.detectUpgradeAdvisory(txn, history);

    if (advisory != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('⚠️ Subscription Upgrade Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${advisory.merchant}: ₹${advisory.oldAmount.toStringAsFixed(0)} ➔ ₹${advisory.newAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.debit, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                advisory.advice,
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel Entry', style: TextStyle(color: AppColors.debit)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    // 1. Spending Freeze Check
    final proceedFreeze = await _checkSpendingFreeze(amount);
    if (!proceedFreeze) {
      setState(() => _isSaving = false);
      return;
    }

    final vaultSaved = AppUtils.calculateRoundup(amount);
    final upiId = _upiIdController.text.trim();
    final txn = Transaction(
      id: widget.editTransaction?.id ?? _uuid.v4(),
      amount: amount,
      merchant: _merchantController.text.trim(),
      category: _selectedCategory,
      date: _selectedDate,
      isSilent: _isSilent,
      mood: _selectedMood,
      isRecurring: _isRecurring,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      fromSms: false,
      isApproved: true,
      vaultSaved: vaultSaved,
      paymentMethod: _selectedPaymentMethod,
      isEmotionalSpend: false,
      upiId: upiId.isEmpty ? null : upiId.toLowerCase(),
      upiApp: _selectedPaymentMethod == 'UPI' ? _selectedUpiApp : null,
    );

    // 2. Upgrade Advisory Check
    final proceedUpgrade = await _checkUpgradeAdvisory(txn);
    if (!proceedUpgrade) {
      setState(() => _isSaving = false);
      return;
    }

    if (widget.editTransaction != null) {
      await ref.read(transactionsProvider.notifier).updateTransaction(txn);
    } else {
      await ref.read(transactionsProvider.notifier).addTransaction(txn);
    }

    setState(() => _isSaving = false);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTransaction != null ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field (prominent)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMOUNT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.debit,
                          ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppColors.debit,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Theme.of(context).dividerColor, fontSize: 40),
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        final d = double.tryParse(v.replaceAll(',', ''));
                        if (d == null || d <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Merchant
              TextFormField(
                controller: _merchantController,
                onChanged: (_) => _autoDetectCategory(),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Description',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter merchant name' : null,
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                'CATEGORY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.defaultCategories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : Theme.of(context).dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.categoryIcons[cat] ?? '💸',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Payment method
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: Theme.of(context).textTheme.bodyMedium,
                items: AppConstants.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedPaymentMethod = v!;
                  if (v != 'UPI') _selectedUpiApp = null;
                }),
              ),
              const SizedBox(height: 16),

              // UPI-specific fields
              if (_selectedPaymentMethod == 'UPI') ...[
                DropdownButtonFormField<String>(
                  value: _selectedUpiApp,
                  decoration: const InputDecoration(
                    labelText: 'UPI App',
                    prefixIcon: Icon(Icons.apps_outlined),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: Theme.of(context).textTheme.bodyMedium,
                  hint: const Text('Select UPI app'),
                  items: AppConstants.upiApps.map((app) {
                    final emoji = AppConstants.upiAppEmojis[app] ?? '💳';
                    return DropdownMenuItem(
                      value: app,
                      child: Text('$emoji  $app'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedUpiApp = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _upiIdController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID / VPA (optional)',
                    prefixIcon: Icon(Icons.alternate_email_outlined),
                    hintText: 'e.g. name@okicici',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!v.contains('@')) return 'Enter a valid UPI ID (e.g. name@okicici)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Theme.of(context).hintColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        AppUtils.formatDate(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Mood picker
              MoodPicker(
                selectedMood: _selectedMood,
                onMoodSelected: (m) => setState(() => _selectedMood = m),
              ),
              const SizedBox(height: 20),

              // Toggles
              _ToggleRow(
                label: 'Silent transaction',
                subLabel: 'Exclude from totals & insights',
                icon: Icons.volume_off_outlined,
                value: _isSilent,
                onChanged: (v) => setState(() => _isSilent = v),
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Recurring',
                subLabel: 'Monthly subscription or bill',
                icon: Icons.repeat,
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(widget.editTransaction != null ? 'Update' : 'Save Transaction'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).hintColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(subLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EmergencyOverrideDialog extends StatefulWidget {
  const _EmergencyOverrideDialog();

  @override
  State<_EmergencyOverrideDialog> createState() => _EmergencyOverrideDialogState();
}

class _EmergencyOverrideDialogState extends State<_EmergencyOverrideDialog> {
  final _reasonController = TextEditingController();
  int _secondsRemaining = 120; // 2 minutes countdown
  Timer? _timer;
  bool _canOverride = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _canOverride = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isReasonFilled = _reasonController.text.trim().isNotEmpty;
    final proceedAllowed = _canOverride && isReasonFilled;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Row(
        children: [
          Text('🧊 Spending Freeze Active'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your spending freeze is currently active to prevent impulse buying.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'To override this freeze in an emergency, you must wait 2 minutes to reflect, and provide a valid reason.',
              style: TextStyle(height: 1.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Reason for override',
                hintText: 'Why is this purchase absolutely necessary?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _secondsRemaining > 0 ? 'Reflect period: $_timeString remaining' : 'Reflect period finished',
                style: TextStyle(
                  color: _secondsRemaining > 0 ? AppColors.amber : AppColors.credit,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel Entry', style: TextStyle(color: Theme.of(context).hintColor)),
        ),
        ElevatedButton(
          onPressed: proceedAllowed
              ? () async {
                  await FreezeManager().saveOverride(_reasonController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: proceedAllowed ? AppColors.accent : Theme.of(context).dividerColor,
          ),
          child: const Text('Override & Save'),
        ),
      ],
    );
  }
}

