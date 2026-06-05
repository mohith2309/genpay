## 2025-05-14 - Exposing Swipe Actions to Screen Readers
**Learning:** Swipeable UI elements (like `TransactionCard`) are often inaccessible to screen reader users who may not be able to perform the required physical gesture. Standard accessibility labels only describe the state, not the available interactions.
**Action:** Always wrap swipeable or gesture-heavy components in a `Semantics` widget and use `customSemanticsActions` to expose the hidden actions (e.g., Delete, Silent, Repeat) as discoverable menu items for screen readers.
