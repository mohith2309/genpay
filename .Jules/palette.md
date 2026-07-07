# Palette's Journal

Critical UX and accessibility learnings for the GenPay application.

Format:
## YYYY-MM-DD - [Title]
**Learning:** [UX/a11y insight]
**Action:** [How to apply next time]

## 2025-05-14 - Haptic Feedback for Selection and Accessibility Tooltips
**Learning:** Adding `HapticFeedback.selectionClick()` to custom chips and interactive elements provides immediate non-visual confirmation of selection, enhancing the tactile experience. Icon-only buttons must always have a `tooltip` or ARIA label to ensure they are accessible to screen readers and provide clarity on hover.
**Action:** Use `HapticFeedback.selectionClick()` for category/mood selections and always provide descriptive tooltips for `IconButton` widgets.
