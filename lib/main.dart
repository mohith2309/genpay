import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart' show AppTheme;
import 'services/hive_service.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/upi/upi_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/vault/vault_screen.dart';
import 'screens/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env is optional. Without a Gemini key the app falls back to on-device
  // keyword categorization, so a missing file must never crash startup.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await HiveService.initialize();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // Let the OS pick icon brightness based on the active theme.
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const ProviderScope(child: GenPayApp()));
}

class GenPayApp extends StatelessWidget {
  const GenPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RootGate(),
    );
  }
}

/// Decides what the user sees first: onboarding, the lock screen, or the app.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isOnboardingDone) return const OnboardingScreen();
    if (auth.isBiometricEnabled && !auth.isAuthenticated) return const LockScreen();
    return const RootNav();
  }
}

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text('GenPay is locked',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Unlock to see your money',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: muted)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).authenticate(),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const List<Widget> _screens = [
    UpiScreen(),
    HomeScreen(),
    InsightsScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  void _onTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments_rounded),
                label: 'Pay'),
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Spends'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights_rounded),
                label: 'Insights'),
            BottomNavigationBarItem(
                icon: Icon(Icons.savings_outlined),
                activeIcon: Icon(Icons.savings_rounded),
                label: 'Vault'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
