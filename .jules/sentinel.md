## 2024-06-12 - Prevent DoS & Data Leakage in Backend
**Vulnerability:** Node.js backend accepted unlimited payload sizes (DoS risk) and leaked error messages `e.message` directly in 500 responses (Data Leakage risk).
**Learning:** `req.on('data')` needs explicit size checking and termination (`req.destroy()`) to prevent memory exhaustion. Generic errors should not expose `e.message`.
**Prevention:** Always enforce a sensible `MAX_PAYLOAD` size limit and use a generic `Internal Server Error` message for client responses while keeping `console.error` for server-side logging.
