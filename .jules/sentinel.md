## 2026-07-09 - [DoS and Info Leak in Node Backend]
**Vulnerability:** Node backend missing payload size limits (DoS risk) and leaking error messages in 500 responses (Information Disclosure).
**Learning:** `req.on('data')` streams buffer everything into memory unless paused and destroyed. Destroying streams within Promises can leave them pending indefinitely if not explicitly resolved/rejected. Generic errors must be returned for 500s.
**Prevention:** Implement limits with `Buffer.byteLength(c)`, pause/destroy streams, and explicitly reject promises. Use generic error messages for the client.
