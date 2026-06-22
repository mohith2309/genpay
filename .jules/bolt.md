## 2024-06-19 - Replaced O(N log N) sorts with O(N) max finding
**Learning:** Sorting an entire list just to find the maximum or minimum element is an unnecessary O(N log N) operation. In performance-critical or frequently run operations, this causes redundant work and memory allocations.
**Action:** When only the maximum, minimum, or "top 1" element is needed from a collection, use an O(N) iteration (`fold` or a simple loop) instead of `.toList()..sort(...)`.
