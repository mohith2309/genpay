## 2025-05-14 - Transaction Card Accessibility & Haptics
**Learning:** Custom swipe-to-reveal gestures in Flutter are inherently inaccessible to screen reader users as they are not standard 'Dismissible' widgets.
**Action:** Always wrap custom gesture-based components in a 'Semantics' widget and provide 'customSemanticsActions' to expose underlying actions like Delete, Toggle, or Repeat to accessibility menus.
