## 2024-05-24 - [TransactionCard Accessibility]
**Learning:** Custom swipe gestures in Flutter (like the horizontal drag on TransactionCard) hide critical functionality from screen reader users. The Semantic tree does not infer these interactions natively.
**Action:** Always wrap interactive list/card components containing custom swipe-to-reveal actions in `Semantics` and use `CustomSemanticsAction` to expose the hidden functionality to accessibility services.
