## 2026-06-07 - Custom Swipe Action Accessibility
**Learning:** Hidden swipe actions in custom gestures (like swipe-to-reveal) are completely invisible to screen readers by default.
**Action:** When implementing custom gestures (e.g. `GestureDetector` doing a manual translation), wrap it in `Semantics` and use `CustomSemanticsAction` to expose hidden actions to screen readers. Pair with `HapticFeedback` for better tactile response.
