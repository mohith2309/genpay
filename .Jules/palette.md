## 2025-01-24 - Accessibility for Custom Swipe Gestures
**Learning:** Swipe-to-reveal actions in mobile apps (like transaction card drawers) are often inaccessible to screen reader users because they rely on specific pointer gestures that conflict with screen reader navigation.
**Action:** Wrap interactive components with custom gestures in a `Semantics` widget and use `CustomSemanticsAction` to expose the hidden actions (e.g., Delete, Edit, Silent) to assistive technologies.

## 2025-01-24 - Standardized Haptic Feedback
**Learning:** Consistent haptic feedback patterns (light for snaps, medium for destructive/major actions, selectionClick for toggles) significantly improve the perceived quality and "tactile" feel of the interface.
**Action:** Apply `HapticFeedback.lightImpact()` when swipe drawers snap into position, `mediumImpact()` for actions like Delete or Duplicate, and `selectionClick()` for state toggles or simple selections.
