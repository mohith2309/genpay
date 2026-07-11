## 2026-07-11 - Conditional Haptics for Auto-Detection
**Learning:** Adding haptic feedback to functions triggered by text input (like auto-categorization matching) can be overwhelming if it fires on every keystroke.
**Action:** Always wrap the haptic trigger in a conditional check to ensure it only fires when the underlying state (e.g., the selected category) actually changes.
