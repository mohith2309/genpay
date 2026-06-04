import '../models/transaction.dart';

class FirebaseService {
  static bool get isConfigured => false;

  Future<void> syncTransaction(Transaction transaction) async {
    // Simulated Firestore/Cloud Function sync
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> syncAll(List<Transaction> transactions) async {
    // Simulated bulk cloud sync
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<Transaction>> fetchCloudTransactions() async {
    // Returns local state as there are no firebase credentials loaded
    return [];
  }
}
