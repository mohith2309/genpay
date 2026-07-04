## 2024-07-04 - Denial of Service via Unbounded Request Payloads
**Vulnerability:** The custom Node.js HTTP server read the entire request body into memory without a size limit, making it vulnerable to DoS attacks via excessively large payloads.
**Learning:** Without framework protections (like Express `body-parser` limits), native `req.on('data')` streams can easily consume all process memory.
**Prevention:** Always enforce a maximum payload limit (e.g., 1MB) using `Buffer.byteLength`, pause the stream (`req.pause()`), send a 413 response, and cleanly destroy the connection (`req.destroy()`).
