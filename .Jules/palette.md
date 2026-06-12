## 2026-06-12 - Custom Swipe Actions Need Semantics
**Learning:** When using custom `GestureDetector` widgets for interactions like swipe-to-reveal (instead of standard dismissibles), those actions are completely invisible to screen readers (TalkBack/VoiceOver). Haptic feedback is also crucial to add tactility to these custom drag interactions.
**Action:** Always wrap interactive custom gestures in `Semantics` with `customSemanticsActions` to expose the hidden functionality to accessibility services, and supplement structural snap-points with `HapticFeedback.lightImpact()`.
