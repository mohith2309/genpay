# Palette's Journal

🎨 UX and Accessibility learnings for GenPay.

## 2025-05-14 - Accessible Swipe Actions in Flutter
**Learning:** Swipe-to-reveal actions (like Delete or Silent) are completely invisible to screen readers unless explicitly exposed via `Semantics`.
**Action:** Wrap custom gesture-based components in a `Semantics` widget and implement `customSemanticsActions`. This allows users to trigger these actions via the system accessibility menu without needing the physical swipe gesture.
