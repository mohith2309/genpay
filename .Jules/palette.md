## 2025-05-14 - Accessible Swipe Actions for Custom Gestures
**Learning:** When using custom `GestureDetector`-based swipe menus instead of the standard `Dismissible` widget, accessibility actions are not automatically provided. Screen reader users cannot "see" or interact with hidden swipe actions (Delete, Silent, Repeat) unless they are explicitly exposed via `customSemanticsActions`.
**Action:** Always wrap custom swipeable components in a `Semantics` widget and map the underlying actions to `customSemanticsActions`. Ensure `package:flutter/semantics.dart` is imported.
