## 2026-06-12 - Redundant sorting in derived Riverpod providers
**Learning:** In Dart, filtering a sorted iterable using `.where()` preserves the original element order. If a base provider yields a sorted list, derived providers mapping or filtering it do not need to re-sort it, saving O(N log N) time complexity.
**Action:** When filtering sorted providers, remove redundant `.sort()` calls on the resulting iterable.
