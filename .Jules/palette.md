## 2025-05-14 - Accessible Swipable List Items
**Learning:** Swipable list items in Flutter (custom implementations using GestureDetector/Transform) are invisible to screen readers unless wrapped in `Semantics` with `customSemanticsActions` defined.
**Action:** Always wrap custom swipable widgets in `Semantics` and provide `CustomSemanticsAction` for each hidden swipe action.
