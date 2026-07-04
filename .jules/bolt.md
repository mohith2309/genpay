## 2024-05-24 - Replace sorting with reduce for max extraction
**Learning:** Sorting an entire list (O(N log N)) just to extract the maximum element is a performance anti-pattern. Dart's `reduce` can do this in O(N).
**Action:** Use `.reduce((a, b) => a.value >= b.value ? a : b)` and always check `.isNotEmpty` to avoid StateErrors when replacing sorting logic.
