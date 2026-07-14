## 2026-07-14 - Information Leak via Late Promise Rejection

**Vulnerability:** Node.js backend would crash with `ERR_HTTP_HEADERS_SENT` when attempting to send a 500 error after already sending a 413 "Payload Too Large" error.

**Learning:** When destroying a request stream early (`req.destroy()`) and rejecting the wrapping Promise, the global error handler will catch that rejected promise. If the global handler naively tries to send a 500 response without checking `res.headersSent`, it will crash the application, causing a DoS.

**Prevention:** Always check `if (res.headersSent) return;` in custom response helper functions (like `send()`) to prevent attempts to write headers multiple times, especially in systems where early stream destruction and promise rejection are used for flow control.
