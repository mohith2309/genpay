## 2024-06-16 - Remove redundant transaction sorting in derived providers
**Learning:** Dart's `Iterable.where` and sequential iteration preserve the original list order. If a base Riverpod provider already sorts the transactions (e.g., `transactionsProvider`), derived providers that simply filter or group these lists do not need to `.sort()` them again.
**Action:** When creating derived state, always check if the base data is already sorted to avoid redundant O(N log N) sorting operations.
