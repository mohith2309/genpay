## 2024-06-15 - Accessible Custom Swipe Actions
**Learning:** Custom gestures like horizontal swipe in transaction cards aren't natively exposed to screen readers. Relying solely on visual reveal mechanics leaves visually impaired users without access to essential actions (Delete, Silent, Repeat).
**Action:** Always wrap custom gesture components in `Semantics` and explicitly expose swipe-triggered actions using `CustomSemanticsAction` conditionally based on the feature's active state. Add standardized `HapticFeedback` to make reveals and actions tactile.
