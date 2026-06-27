import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../models/bank_account.dart';

/// Secure UPI PIN entry, styled like the NPCI common library sheet.
///
/// Pass [onSubmit]; it receives the entered PIN and returns true to accept
/// (the screen pops with `true`) or false to reject (dots clear + error shake).
class UpiPinScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final BankAccount account;
  final int pinLength;
  final Future<bool> Function(String pin) onSubmit;

  const UpiPinScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.account,
    required this.onSubmit,
    this.pinLength = 6,
  });

  @override
  State<UpiPinScreen> createState() => _UpiPinScreenState();
}

class _UpiPinScreenState extends State<UpiPinScreen> {
  String _pin = '';
  bool _checking = false;
  bool _error = false;

  Future<void> _onKey(String k) async {
    if (_checking) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = false;
      if (k == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < widget.pinLength) {
        _pin += k;
      }
    });
    if (_pin.length == widget.pinLength) {
      setState(() => _checking = true);
      final ok = await widget.onSubmit(_pin);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _checking = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bank header (NPCI sheet style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(widget.account.colorValue)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.account_balance,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.account.bankName,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(widget.account.maskedAccount,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                  const Spacer(),
                  // Secure-connection cue (Gemini's note)
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: AppColors.credit, size: 14),
                      const SizedBox(width: 4),
                      Text('Secured',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.credit,
                                letterSpacing: 0.2,
                              )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              _error ? 'Incorrect UPI PIN. Try again.' : widget.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _error
                        ? AppColors.debit
                        : Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 32),

            // PIN dots — hollow circles that fill with indigo on entry
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pinLength, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: filled ? 18 : 16,
                  height: filled ? 18 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: _error
                          ? AppColors.debit
                          : (filled
                              ? AppColors.accent
                              : Theme.of(context).dividerColor),
                      width: 2,
                    ),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 24,
              child: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent))
                  : null,
            ),

            const Spacer(),
            _PinPad(onKey: _onKey),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onKey;
  const _PinPad({required this.onKey});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _keys.map((row) {
          return Row(
            children: row.map((k) {
              if (k.isEmpty) return const Expanded(child: SizedBox(height: 64));
              return Expanded(
                child: InkWell(
                  onTap: () => onKey(k),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 64,
                    alignment: Alignment.center,
                    child: k == '⌫'
                        ? Icon(Icons.backspace_outlined,
                            color: Theme.of(context).colorScheme.onSurface)
                        : Text(k,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
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
