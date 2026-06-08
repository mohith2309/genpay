## 2024-05-15 - Redundant Sorting in Derived Providers
**Learning:** Dart`s `Iterable.where` preserves the original list order. We have a pattern where a base Riverpod provider fetches and sorts a list, and then multiple derived providers filter that list and sort it again.
**Action:** Avoid calling `.sort()` in derived providers if the base list is already sorted by the same criteria. This changes O(n log n) operations to O(n) operations.
