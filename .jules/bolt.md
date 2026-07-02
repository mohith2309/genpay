## 2024-05-18 - Optimize O(N log N) sorting to O(N) reduce
**Learning:** Dart's list `.sort()` combined with `.first` is often used to extract the maximum or minimum element, but it requires O(N log N) time and allocates a new list. This is a common performance anti-pattern.
**Action:** Replace this pattern with an O(N) `.reduce()` operation (e.g., `list.reduce((a, b) => a.value >= b.value ? a : b)`) to improve performance and avoid unnecessary memory allocation, making sure to check for empty collections where appropriate.
