## 2025-05-14 - Standardizing Tactile Feedback
**Learning:** Users in financial apps benefit from immediate non-visual confirmation for destructive (Delete) and state-toggle (Silent) actions. Standardizing on `mediumImpact` for destructive and `selectionClick` for toggles creates a predictable physical language.
**Action:** Use `HapticFeedback.mediumImpact()` for deletes/duplicates and `HapticFeedback.selectionClick()` for toggles/selections.
