## 2025-02-12 - [Feedback & Safety]
**Learning:** [UX/a11y insight]
Haptic feedback is essential for non-visual confirmation on mobile, but code safety (mounted checks) is equally critical during asynchronous operations.

**Action:** [How to apply next time]
Always add `if (mounted)` checks before calling `setState` in Flutter widgets, especially within async callbacks, and use `HapticFeedback` for significant user actions to improve tactile delight.
