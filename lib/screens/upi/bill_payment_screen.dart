import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/billers.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/bank_provider.dart';
import '../../services/bharat_connect_service.dart';
import 'payment_status_screen.dart';
import 'upi_pin_screen.dart';

/// Categories whose bills genuinely recur monthly — paying one marks it as a
/// recurring transaction so it feeds the Subscriptions & AutoPay screen.
const _recurringCategories = {
  'electricity', 'broadband', 'dth', 'water', 'gas', 'insurance', 'loan',
};

class BillPaymentScreen extends ConsumerStatefulWidget {
  final BillerCategory category;
  final Biller biller;

  const BillPaymentScreen(
      {super.key, required this.category, required this.biller});

  @override
  ConsumerState<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends ConsumerState<BillPaymentScreen> {
  final _uuid = const Uuid();
  final _consumerController = TextEditingController();

  bool _fetching = false;
  bool _processing = false;
  FetchedBill? _bill;
  RechargePlan? _plan;
  double _payAmount = 0;

  bool get _isMobile => widget.category.key == 'mobile';

  @override
  void dispose() {
    _consumerController.dispose();
    super.dispose();
  }

  Future<void> _fetchBill() async {
    if (_consumerController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _fetching = true);
    final bill = await BharatConnectService.fetchBill(
      biller: widget.biller,
      category: widget.category,
      consumerNumber: _consumerController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _bill = bill;
      _payAmount = bill.amount;
    });
  }

  void _selectPlan(RechargePlan plan) {
    setState(() {
      _plan = plan;
      _payAmount = plan.amount;
    });
  }

  Future<void> _pay() async {
    if (_payAmount <= 0) return;
    final account = ref.read(primaryAccountProvider);
    if (account == null) return;

    if (account.balance < _payAmount) {
      _goToStatus(success: false, error: 'Insufficient balance in ${account.bankName}');
      return;
    }

    HapticFeedback.mediumImpact();
    final approved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPinScreen(
          title: 'Enter UPI PIN',
          subtitle:
              'to pay ${AppUtils.formatCurrency(_payAmount)} to ${widget.biller.name}',
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

    await ref.read(bankAccountsProvider.notifier).debit(account.id, _payAmount);
    final isRecurring = _recurringCategories.contains(widget.category.key);
    final txn = Transaction(
      id: _uuid.v4(),
      amount: _payAmount,
      merchant: widget.biller.name,
      category: widget.biller.spendCategory,
      date: DateTime.now(),
      note: _isMobile
          ? 'Recharge • ${_consumerController.text.trim()}'
          : 'Bill • ${_consumerController.text.trim()}',
      fromSms: false,
      isApproved: true,
      isRecurring: isRecurring,
      vaultSaved: AppUtils.calculateRoundup(_payAmount),
      paymentMethod: 'UPI',
      upiApp: 'Bharat Connect',
    );
    await ref.read(transactionsProvider.notifier).addTransaction(txn);
    _goToStatus(success: true);
  }

  void _goToStatus({required bool success, String? error}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          success: success,
          amount: _payAmount,
          payeeName: widget.biller.name,
          payeeVpa: 'Bharat Connect • ${widget.category.label}',
          paymentId: success
              ? 'BC${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}'
              : null,
          errorMessage: error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.biller.name),
        bottom: const _BharatConnectStrip(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Consumer reference input
          TextField(
            controller: _consumerController,
            keyboardType: widget.category.numericRef
                ? TextInputType.number
                : TextInputType.text,
            textCapitalization: widget.category.numericRef
                ? TextCapitalization.none
                : TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: widget.category.consumerLabel,
              hintText: widget.category.consumerHint,
              prefixIcon: const Icon(Icons.tag),
            ),
            onChanged: (_) => setState(() {
              _bill = null;
              _plan = null;
              _payAmount = 0;
            }),
          ),
          const SizedBox(height: 16),

          if (_isMobile)
            ..._buildRechargeFlow()
          else
            ..._buildBillFlow(),
        ],
      ),
    );
  }

  // ── Bill (fetch) flow ───────────────────────────────────────────────────────

  List<Widget> _buildBillFlow() {
    return [
      if (_bill == null)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_consumerController.text.trim().isEmpty || _fetching)
                ? null
                : _fetchBill,
            icon: _fetching
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                : const Icon(Icons.search),
            label: Text(_fetching ? 'Fetching bill…' : 'Fetch Bill'),
          ),
        )
      else ...[
        _BillCard(bill: _bill!),
        const SizedBox(height: 20),
        _payButton(),
      ],
    ];
  }

  // ── Recharge (plans) flow ─────────────────────────────────────────────────────

  List<Widget> _buildRechargeFlow() {
    return [
      Text('POPULAR PLANS',
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      ...BharatConnectService.rechargePlans.map((p) {
        final selected = _plan?.amount == p.amount;
        return GestureDetector(
          onTap: () => _selectPlan(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.electricBlue.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected ? AppColors.electricBlue : Theme.of(context).dividerColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppUtils.formatCurrency(p.amount),
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(p.validity,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(p.benefit,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.electricBlue, size: 20),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 10),
      if (_plan != null) _payButton(),
    ];
  }

  Widget _payButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_payAmount > 0 && !_processing) ? _pay : null,
        child: _processing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
            : Text('Pay ${AppUtils.formatCurrency(_payAmount)}'),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final FetchedBill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BILL DETAILS',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 2)),
              if (bill.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.softRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('OVERDUE',
                      style: TextStyle(
                          color: AppColors.softRed,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppUtils.formatCurrency(bill.amount),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(width: 12),
              // Stark "DUE" badge (Gemini): primary-color block, high contrast.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('DUE',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row(context, 'Customer', bill.customerName),
          _row(context, 'Consumer No.', bill.consumerNumber),
          _row(context, 'Bill number', bill.billNumber),
          _row(context, 'Bill date', AppUtils.formatDate(bill.billDate)),
          _row(context, 'Due date', AppUtils.formatDate(bill.dueDate),
              valueColor: bill.isOverdue ? AppColors.debit : null),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BharatConnectStrip extends StatelessWidget implements PreferredSizeWidget {
  const _BharatConnectStrip();

  @override
  Size get preferredSize => const Size.fromHeight(28);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFF1A8754)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Bharat Connect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Text('Secured by NPCI BBPS',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
