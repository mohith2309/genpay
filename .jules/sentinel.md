## 2024-05-24 - DoS via Unbounded Payload Parsing in Node.js
**Vulnerability:** Missing request payload size limit, leading to potential OOM/DoS attacks.
**Learning:** When manually handling streams, it's not enough to check the size and destroy the request. You must properly reject pending promises and handle headers states, or the stream end event might crash the server or hang connections.
**Prevention:** Always implement payload limits using `Buffer.byteLength(chunk)` with `req.destroy()`, handle promise rejection securely, and guard custom response wrappers with `if (res.headersSent) return;`.
