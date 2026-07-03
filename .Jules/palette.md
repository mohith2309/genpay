## 2024-05-24 - Semantics for Swipe Cards
**Learning:** When using custom semantics actions for swipeable cards, `customSemanticsActions` should be conditionally nullified based on whether swipe actions are active. Also, `HitTestBehavior.opaque` is crucial for background buttons to intercept taps properly.
**Action:** Conditionally apply semantics actions and enforce opaque hit tests on custom interactive background elements.
