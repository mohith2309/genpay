## 2025-05-14 - Accessible Custom Swipe Gestures in Flutter
**Learning:** Standard horizontal swipe gestures implemented with `GestureDetector` are invisible to screen readers like TalkBack and VoiceOver. To make them accessible, components must be wrapped in a `Semantics` widget with `customSemanticsActions` defined.
**Action:** When implementing custom drag-to-reveal or swipe-to-dismiss patterns, always provide `customSemanticsActions` that map to the underlying logic, ensuring keyboard and screen reader users can trigger the same actions.
