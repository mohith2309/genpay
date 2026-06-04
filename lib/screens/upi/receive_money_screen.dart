import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/payee_provider.dart';
import '../../services/upi_service.dart';
import 'request_money_screen.dart';

class ReceiveMoneyScreen extends ConsumerStatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  ConsumerState<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends ConsumerState<ReceiveMoneyScreen> {
  final _amountController = TextEditingController();
  double? _requestAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _editProfile(String currentVpa, String currentName) {
    final vpaController = TextEditingController(text: currentVpa);
    final nameController = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your UPI profile',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vpaController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontFamily: 'JetBrains Mono'),
              decoration: const InputDecoration(
                labelText: 'Your UPI ID',
                hintText: 'yourname@okicici',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final vpa = vpaController.text.trim();
                  if (!UpiService.isValidVpa(vpa)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Enter a valid UPI ID like name@okicici')),
                    );
                    return;
                  }
                  ref.read(myUpiProfileProvider.notifier).update(
                        vpa: vpa,
                        name: nameController.text.trim(),
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myUpiProfileProvider);
    final hasVpa = profile.vpa.isNotEmpty;

    final qrData = hasVpa
        ? UpiService.buildUri(
            payeeVpa: profile.vpa,
            payeeName: profile.name,
            amount: _requestAmount,
          )
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_received),
            tooltip: 'Request from a UPI ID',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestMoneyScreen()),
            ),
          ),
          if (hasVpa)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final text =
                    'Pay me${_requestAmount != null ? ' ${AppUtils.formatCurrency(_requestAmount!)}' : ''} on UPI: ${profile.vpa}';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment request copied to share')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!hasVpa) ...[
              const SizedBox(height: 40),
              Icon(Icons.qr_code_2,
                  size: 64, color: Theme.of(context).hintColor),
              const SizedBox(height: 16),
              Text(
                'Set your UPI ID to generate\nyour personal QR code',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _editProfile('', profile.name),
                icon: const Icon(Icons.add),
                label: const Text('Add your UPI ID'),
              ),
            ] else ...[
              // QR card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      profile.vpa,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    if (_requestAmount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Requesting ${AppUtils.formatCurrency(_requestAmount!)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Scan with any UPI app to pay you',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 24),

              // Request specific amount
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Request a specific amount (optional)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (v) {
                        setState(() => _requestAmount = double.tryParse(v));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(ClipboardData(text: profile.vpa));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy ID'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editProfile(profile.vpa, profile.name),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
