## 2024-06-08 - Added Accessible Custom Swipe Actions
**Learning:** Swipe actions in interactive lists (like `TransactionCard`) are inherently inaccessible to screen readers out-of-the-box in Flutter.
**Action:** When implementing custom gestures (like horizontal dragging) for actions, always wrap the component in `Semantics` and use `CustomSemanticsAction` to expose those actions (e.g., Delete, Repeat, Silent) to assistive technologies.
