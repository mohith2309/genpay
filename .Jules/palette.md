## 2026-06-18 - Accessible Swipe Actions
**Learning:** Custom swipe-to-reveal implementations (not using standard Dismissible) are invisible to screen readers, preventing access to critical actions like Delete or Silent.
**Action:** Wrap custom swipeable widgets in `Semantics` and provide `customSemanticsActions` to expose the hidden functionality to assistive technologies.
