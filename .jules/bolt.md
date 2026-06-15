## 2024-06-15 - Riverpod Derived Sorting
**Learning:** Dart`s `Iterable.where` and sequential iteration preserve the original list order. `transactionsProvider` already sorts by date descending.
**Action:** Avoid redundant `.sort()` operations in derived Riverpod providers or grouped data structures if the base provider`s list is already sorted.
