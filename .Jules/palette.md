## $(date +%Y-%m-%d) - TransactionCard custom semantics

**Learning:** When using custom gestures (like swipe actions) in Flutter list items, the actions are hidden from screen readers unless explicitly exposed. Using `CustomSemanticsAction` on the parent widget maps these logical actions to the accessibility tree.
**Action:** When adding custom gesture controls that reveal hidden actions, wrap the gesture detector in a `Semantics` widget and map the actions using `customSemanticsActions`.
