## 2024-06-16 - Add Semantic Actions to Custom Gestures
**Learning:** Custom gestures (like horizontal swipes on cards) are inaccessible to screen readers by default. We must use `Semantics` with `CustomSemanticsAction` to expose these hidden actions.
**Action:** Always wrap widgets implementing custom swipe/drag logic with `Semantics` and define `customSemanticsActions` to ensure parity for assistive technologies.
