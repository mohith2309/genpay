## 2024-07-11 - Stream handling with Payload Limits
**Vulnerability:** Node.js backend read complete request payloads into memory without size limits, and `e.message` was leaked in 500 responses.
**Learning:** When destroying a Node.js request stream early (e.g., calling `req.destroy()` after exceeding limits) while parsing inside a Promise, we must explicitly reject the Promise and add `if (req.destroyed) return;` in the `req.on('end')` handler to prevent memory leaks and "headers already sent" errors.
**Prevention:** Always enforce a max payload size limit on endpoints processing `req.on('data')`, handle early stream destruction gracefully within Promises, and return generic messages in global error catches.
