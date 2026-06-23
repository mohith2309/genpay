## 2024-05-15 - Replace O(N log N) sorting with O(N) reduce
**Learning:** Found multiple instances where entire maps/lists were converted to lists and sorted (`.toList()..sort(...)`) just to find the single maximum element (e.g. `topCat`, `biggestCategory`). This is an O(N log N) operation for something that should be an O(N) single pass.
**Action:** Use `.reduce((a, b) => a.value > b.value ? a : b)` when finding a max/min element in a collection to avoid unnecessary sorting overhead.
