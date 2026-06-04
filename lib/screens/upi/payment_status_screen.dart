import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class PaymentStatusScreen extends StatefulWidget {
  final bool success;
  final double amount;
  final String payeeName;
  final String payeeVpa;
  final String? paymentId;
  final String? errorMessage;

  const PaymentStatusScreen({
    super.key,
    required this.success,
    required this.amount,
    required this.payeeName,
    required this.payeeVpa,
    this.paymentId,
    this.errorMessage,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.credit : AppColors.debit;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Status icon — solid disc, heavy mark scales in (~300ms)
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.success ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 56,
              ),
            )
                .animate()
                .scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 180.ms),
            const SizedBox(height: 28),

            Text(
              widget.success ? 'Payment Successful' : 'Payment Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),

            Text(
              AppUtils.formatCurrency(widget.amount),
              style: Theme.of(context).textTheme.displaySmall,
            ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 6),

            Text(
              widget.success
                  ? 'Paid to ${widget.payeeName}'
                  : (widget.errorMessage ?? 'Something went wrong'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 24),

            // Receipt card — expands in after the mark lands
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _receiptRow('To', widget.payeeName),
                  const Divider(height: 20),
                  _receiptRow('UPI ID', widget.payeeVpa),
                  if (widget.paymentId != null) ...[
                    const Divider(height: 20),
                    _receiptRow('Txn ID', widget.paymentId!),
                  ],
                  const Divider(height: 20),
                  _receiptRow('Date', AppUtils.formatDate(DateTime.now())),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 450.ms)
                .slideY(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOut),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).hintColor, fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    });
  }
}
