## 2024-11-20 - Accessible Swipe Actions
**Learning:** Screen readers cannot inherently discover swipe-to-reveal actions (like left/right drag gestures to reveal action buttons) commonly used in transaction cards or list items.
**Action:** Wrap such components in a `Semantics` widget and map the hidden actions using `customSemanticsActions` (e.g., `CustomSemanticsAction(label: 'Delete')`) to ensure they are fully accessible to screen readers.
