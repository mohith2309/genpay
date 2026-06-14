## 2025-01-24 - Haptics and Accessibility for Custom Swipe Actions
**Learning:** Custom swipe gestures (using `GestureDetector`) lack native haptic feedback and screen reader accessibility that standard widgets like `Dismissible` provide. These must be manually implemented to ensure a delightful and inclusive experience.
**Action:** Always wrap custom interactive components in `Semantics` and use `CustomSemanticsAction` to expose hidden actions to screen readers. Map appropriate `HapticFeedback` (light/medium/selectionClick) to interaction phases (snap, destructive action, state toggle).
