## 2026-06-11 - Avoid redundant sorting in derived Riverpod providers
**Learning:** In Dart, `Iterable.where()` preserves the original list order. When creating a derived Riverpod provider that filters a list from a base provider, avoid redundant `.sort()` operations if the base list is already sorted. This prevents unnecessary O(N log N) operations and improves performance.
**Action:** Before calling `.sort()` on a filtered list, check if the source list is already sorted and relies on order-preserving methods like `.where()`.
