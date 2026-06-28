## 2024-05-24 - Avoid O(N log N) sorting for finding max element in iterables
**Learning:** Dart's Map/List operations frequently chain `.toList()..sort(...)` just to extract the maximum or minimum element. This unnecessarily allocates a new list in memory and takes O(N log N) time complexity.
**Action:** Replace `collection.toList()..sort(...)` with `collection.reduce(...)` to find the maximum or minimum element in O(N) time with zero extra memory allocation, checking for `isNotEmpty` if the collection can potentially be empty.
