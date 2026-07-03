## 2024-07-03 - O(N log N) to O(N) max element extraction
**Learning:** Dart's `reduce` is safer and faster for finding maximum values in collections without sorting the entire collection. However, calling `reduce` on an empty collection throws a `StateError`. Always check `.isNotEmpty` or provide a fallback.
**Action:** When optimizing sort-first operations to find a max/min element using `reduce`, wrap the operation in an `isNotEmpty` check to avoid runtime errors, especially with dynamic data sources like maps grouped from user transactions.
