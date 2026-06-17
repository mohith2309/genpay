## 2024-06-17 - Accessible Custom Gestures
**Learning:** Custom implementations for swipe actions (unlike Dismissible) are invisible to screen readers, leaving users stuck.
**Action:** Always wrap custom gesture components in Semantics and expose interactions via CustomSemanticsAction.
