## 2026-07-03 - Accessible Custom Gestures
**Learning:** When implementing accessibility for custom gestures like swipe-to-reveal in Flutter, `customSemanticsActions` should be conditionally nullified if the underlying visual gesture is disabled (e.g., via a `showSwipeActions` flag). This ensures the accessibility tree remains consistent with the visual UI and prevents screen readers from announcing phantom actions.
**Action:** Always wrap custom gesture widgets in `Semantics` and use conditional logic for `customSemanticsActions` based on the widget's enabled state.
