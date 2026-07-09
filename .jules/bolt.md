## 2026-07-09 - Replace sort().first with reduce()
**Learning:** Using `.sort((a,b) => ...).first` to find the maximum element in a list is O(N log N).
**Action:** Always replace `.sort().first` with `.reduce((a,b) => a >= b ? a : b)` when finding a max/min element, reducing time complexity to O(N).
