## 2024-06-25 - Avoid sorting to find maximum
**Learning:** Found multiple instances where entire maps/lists were converted and sorted (O(N log N)) just to find the top element (e.g., top spending category). This codebase-specific pattern of sorting `entries.toList()..sort(...)` allocates unnecessary lists and is inefficient.
**Action:** Replace `entries.toList()..sort().first` with an O(N) `reduce` operation to find the maximum without allocating a list, checking for `isEmpty` to avoid `StateError`.
