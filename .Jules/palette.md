## 2026-07-13 - Accessible Swipe Actions in Flutter
**Learning:** Custom swipe gestures in Flutter are invisible to screen readers. Pairing `Semantics` with `customSemanticsActions` allows accessibility services to discover and trigger these hidden actions. Using `ExcludeSemantics` on the visual background buttons prevents the screen reader from focusing on hidden elements.
**Action:** Always implement `customSemanticsActions` when using custom drag-to-reveal patterns and use `ExcludeSemantics` to keep the tree clean.
