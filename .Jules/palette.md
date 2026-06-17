## 2026-06-17 - Accessible Custom Swipe Actions
**Learning:** Custom swipe-to-action patterns implemented with GestureDetector are invisible to screen readers. Wrapping them in Semantics with customSemanticsActions exposes these hidden interactions to assistive technologies.
**Action:** Always pair custom drag gestures with Semantics actions when they reveal or trigger primary UI functionality.
