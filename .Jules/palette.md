
## 2024-05-18 - Tooltips for Icon-Only Buttons
**Learning:** Found multiple instances where `IconButton` widgets lacked a `tooltip` attribute. Without this, screen readers may read the icon name generically (e.g., "button") or not at all, leading to a poor accessibility experience.
**Action:** Always provide a concise and descriptive `tooltip` for icon-only interactive elements to ensure their function is clearly communicated to screen reader users and those relying on visual tooltips.
