import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/billers.dart';
import 'bill_payment_screen.dart';

/// Bharat Connect (BBPS) bill payment hub. Category grid → biller list →
/// fetch/recharge → pay via Razorpay UPI.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bills & Recharge')),
      body: Column(
        children: [
          const _PoweredByBharatConnect(),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: Billers.categories.map((c) {
                return _CategoryTile(
                  category: c,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BillerListScreen(category: c),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoweredByBharatConnect extends StatelessWidget {
  const _PoweredByBharatConnect();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFF1A8754)],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('Bharat Connect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pay any biller on India\'s BBPS network',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final BillerCategory category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            alignment: Alignment.center,
            child: Text(category.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            category.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Lists the registered billers within a category.
class BillerListScreen extends StatelessWidget {
  final BillerCategory category;
  const BillerListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('SELECT BILLER',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          ...category.billers.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child:
                        Text(category.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  title: Text(b.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context).hintColor),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BillPaymentScreen(category: category, biller: b),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
