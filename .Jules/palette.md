## 2025-05-14 - Exposing Custom Swipes to Screen Readers
**Learning:** Custom horizontal swipe gestures in Flutter (implemented via GestureDetector) are invisible to screen readers unless explicitly bridged via the Semantics system. Users relying on TalkBack or VoiceOver cannot discover or trigger background actions (like Delete or Silent) revealed by swiping.
**Action:** Always wrap custom-swipeable components in a `Semantics` widget and use `customSemanticsActions` to expose those actions as labeled accessibility commands.
