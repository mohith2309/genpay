## 2025-05-15 - Enhancing Swipeable Card Accessibility
**Learning:** Custom swipe gestures in Flutter widgets (using `GestureDetector`) are invisible to screen readers by default. Providing `Semantics` with `CustomSemanticsAction` is essential to expose these actions to accessibility services.
**Action:** Always wrap custom interactive components in `Semantics` and use `CustomSemanticsAction` to ensure all functionality is accessible via screen readers.
