## 2024-06-21 - Avoid redundant sorting in derived Riverpod providers
**Learning:** Dart's `Iterable.where` preserves the original list order. When a base Riverpod provider already sorts its list (e.g., by date), derived providers that only filter the data do not need to perform redundant `.sort()` operations.
**Action:** Always check the sorting behavior of the base data source before adding `.sort()` to derived lists or providers to avoid unnecessary O(n log n) operations.
