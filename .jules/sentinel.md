
## 2024-05-30 - Fix Information Disclosure and Add DoS Protection in Custom Node.js Server
**Vulnerability:** The server was vulnerable to Denial of Service (DoS) due to unbounded payload parsing in `readBody`, and Information Disclosure as the global error handler returned raw `e.message` in 500 responses.
**Learning:** When building custom zero-dependency Node.js servers, request payload sizes must be manually enforced using `Buffer.byteLength(chunk)` with `req.pause()`, a 413 response, and `req.destroy()`. Additionally, any unexpected error thrown could leak sensitive stack traces or internal state strings to the client if the `e.message` is returned directly.
**Prevention:** Always implement explicit size checks inside `req.on('data')` streams, check `res.headersSent` to avoid header collision on premature request termination, and ensure global error boundaries always map to generic error strings like "Internal server error" for production clients.
