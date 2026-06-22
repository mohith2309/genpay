## 2025-02-18 - Accessible Swipe Actions & Haptics
**Learning:** Custom swipe gestures in Flutter lack inherent screen reader visibility and physical feedback, compared to native components.
**Action:** Always implement `Semantics` with `customSemanticsActions` and add `HapticFeedback` to custom interactive components to ensure full accessibility and physical response.
