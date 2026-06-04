import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/payee.dart';
import '../models/bank_account.dart';
import '../core/constants.dart';

class HiveService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(PayeeAdapter());
    Hive.registerAdapter(BankAccountAdapter());
    _initialized = true;
  }

  static Future<Box<Transaction>> openTransactionsBox() async {
    if (Hive.isBoxOpen(AppConstants.transactionsBox)) {
      return Hive.box<Transaction>(AppConstants.transactionsBox);
    }
    return await Hive.openBox<Transaction>(AppConstants.transactionsBox);
  }

  static Future<Box<Budget>> openBudgetsBox() async {
    if (Hive.isBoxOpen(AppConstants.budgetsBox)) {
      return Hive.box<Budget>(AppConstants.budgetsBox);
    }
    return await Hive.openBox<Budget>(AppConstants.budgetsBox);
  }

  static Future<Box<Category>> openCategoriesBox() async {
    if (Hive.isBoxOpen(AppConstants.categoriesBox)) {
      return Hive.box<Category>(AppConstants.categoriesBox);
    }
    return await Hive.openBox<Category>(AppConstants.categoriesBox);
  }

  static Future<Box> openSettingsBox() async {
    if (Hive.isBoxOpen(AppConstants.settingsBox)) {
      return Hive.box(AppConstants.settingsBox);
    }
    return await Hive.openBox(AppConstants.settingsBox);
  }

  static Future<Box> openVaultBox() async {
    if (Hive.isBoxOpen(AppConstants.vaultBox)) {
      return Hive.box(AppConstants.vaultBox);
    }
    return await Hive.openBox(AppConstants.vaultBox);
  }

  static Future<Box> openPauseModeBox() async {
    if (Hive.isBoxOpen(AppConstants.pauseModeBox)) {
      return Hive.box(AppConstants.pauseModeBox);
    }
    return await Hive.openBox(AppConstants.pauseModeBox);
  }

  static Future<Box> openGeminiCacheBox() async {
    if (Hive.isBoxOpen(AppConstants.geminiCacheBox)) {
      return Hive.box(AppConstants.geminiCacheBox);
    }
    return await Hive.openBox(AppConstants.geminiCacheBox);
  }

  static Future<Box<Payee>> openPayeesBox() async {
    if (Hive.isBoxOpen(AppConstants.payeesBox)) {
      return Hive.box<Payee>(AppConstants.payeesBox);
    }
    return await Hive.openBox<Payee>(AppConstants.payeesBox);
  }

  static Future<Box<BankAccount>> openBankAccountsBox() async {
    if (Hive.isBoxOpen(AppConstants.bankAccountsBox)) {
      return Hive.box<BankAccount>(AppConstants.bankAccountsBox);
    }
    return await Hive.openBox<BankAccount>(AppConstants.bankAccountsBox);
  }

  static Future<void> clearAll() async {
    final boxes = [
      AppConstants.transactionsBox,
      AppConstants.budgetsBox,
      AppConstants.categoriesBox,
      AppConstants.settingsBox,
      AppConstants.vaultBox,
      AppConstants.pauseModeBox,
      AppConstants.geminiCacheBox,
      AppConstants.payeesBox,
      AppConstants.bankAccountsBox,
    ];
    for (final name in boxes) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      }
    }
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }
}
