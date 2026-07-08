## 2025-05-14 - Haptic Feedback in Auto-detection Loops
**Learning:** Adding haptic feedback to functions triggered by text input (like auto-categorization) can cause excessive vibrations if triggered on every keystroke, even when the state hasn't changed.
**Action:** Always wrap haptic triggers in a conditional check to ensure they only fire when the underlying state (e.g., selected category) actually changes.
