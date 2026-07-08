## 2026-07-08 - Prevent DoS via Payload Size Limits and Info Disclosure
**Vulnerability:** Server had no payload size limit (DoS risk) and exposed raw errors in 500 responses (Information Disclosure).
**Learning:** Node.js HTTP streams (`req.on('data')`) will accept unbounded input leading to OOM. Global catch blocks often leak sensitive info.
**Prevention:** Always enforce a max bytes limit (e.g., 1MB) on incoming streams and `destroy()` the request. Never send `e.message` in 500 API responses.
