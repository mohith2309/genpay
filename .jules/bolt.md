## 2025-06-18 - Avoid redundant sorts in derived providers
**Learning:** Dart's `Iterable.where` and sequential iteration (like grouping into a map) preserve the original list's order. If a base Riverpod provider serves a pre-sorted list, deriving state by filtering or grouping does not require re-sorting. Re-sorting introduces O(N log N) overhead per update instead of O(N).
**Action:** Always check the sorting guarantee of the base provider before adding `.sort()` in derived providers or grouped data structures.
