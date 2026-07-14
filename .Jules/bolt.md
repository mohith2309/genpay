## 2024-07-14 - Replace sort().first with reduce()
**Learning:** Using `sort().first` or `sort().firstOrNull` to find the maximum element in a Map/List creates unnecessary intermediate lists and takes O(n log n) time.
**Action:** Use `reduce()` with `>=` (to preserve tie-breaking) guarded by `isNotEmpty` for O(n) maximum finding without intermediate lists.
