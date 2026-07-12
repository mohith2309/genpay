## 2024-07-12 - ⚡ Bolt: Optimize element lookups
**Learning:** In Dart/Flutter, finding the maximum/latest element in a list (e.g. `transactions`) was frequently done using `.toList()..sort((a,b) => ...).first`. This requires O(n log n) time and often allocates an intermediate list just to find a single element.
**Action:** When finding a minimum/maximum element, always use `reduce()` instead of `sort().first`. E.g., `list.reduce((a, b) => a.value >= b.value ? a : b)`. Be sure to guard against empty lists with `isNotEmpty` and handle ties appropriately using `>=`.
