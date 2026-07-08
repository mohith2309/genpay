## 2026-07-08 - Replaced sort().first with reduce()
**Learning:** Using `.toList()..sort((a,b) => ...).first` to find the maximum element has O(N log N) complexity and allocates a new list. This is a common anti-pattern in Dart.
**Action:** Use `.reduce((a, b) => a.value >= b.value ? a : b)` instead for an O(N) operation without extra allocations. Always check `.isNotEmpty` before calling `.reduce()` to avoid `StateError`.
