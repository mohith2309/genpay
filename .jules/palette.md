## 2026-07-11 - Exposing Custom Swipe Actions to Screen Readers
**Learning:** Custom interactive gestures (like horizontal dragging/swiping on a card) are completely invisible to screen readers, preventing visually impaired users from discovering or using hidden actions.
**Action:** Always wrap custom gesture widgets in a `Semantics` widget and explicitly map the actions using `customSemanticsActions`. Conditionally nullify these actions when the visual actions are disabled to prevent the screen reader from announcing phantom interactive elements.
