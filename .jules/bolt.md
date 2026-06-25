## 2024-06-25 - Replace map sort-and-first with linear reduce
**Learning:** Avoid sorting map entries (`.entries.toList()..sort()`) just to extract the maximum element, as it takes O(N log N) time and unnecessarily allocates list memory.
**Action:** Use an O(N) `.reduce()` operation (e.g., `entries.reduce((a, b) => a.value > b.value ? a : b)`) to find the maximum element efficiently.
