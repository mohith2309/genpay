## 2024-05-24 - Custom Gestures Require Manual Semantics
**Learning:** In Flutter, when building swipeable widgets using a custom `GestureDetector` (e.g., to support multi-action reveals like in `TransactionCard`) rather than the native `Dismissible`, it breaks standard screen reader accessibility for those actions.
**Action:** When implementing custom gestures that replace standard interactive widgets, always wrap the widget in a `Semantics` widget and use `CustomSemanticsAction` to manually expose the hidden actions to TalkBack/VoiceOver users.
