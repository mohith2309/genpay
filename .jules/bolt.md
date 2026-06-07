## 2024-06-07 - Redundant sorting in derived providers
**Learning:** Riverpod providers (like `currentMonthTransactionsProvider`) derive state from a base `transactionsProvider` that is already sorted by date descending on load. Re-sorting the filtered lists using `..sort((a, b) => b.date.compareTo(a.date))` is redundant O(N log N) work that happens on every state change. `Iterable.where` in Dart preserves the original list order.
**Action:** When deriving state from a provider that already maintains sorted order, trust the base order and avoid redundant sorting operations.
