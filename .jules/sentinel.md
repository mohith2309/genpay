## 2025-02-12 - Prevent DoS via Payload Size Limit & Stop Info Disclosure
**Vulnerability:** Node.js server lacked payload size limits in `readBody`, allowing memory exhaustion (DoS). Also, the global error handler returned raw `e.message` to the client, leading to Information Disclosure.
**Learning:** In custom zero-dependency Node servers, request streams must manually implement size limits, pause and destroy the request, and check if headers were sent. Global error handlers must always return generic responses (e.g. 'Internal server error').
**Prevention:** Always track `Buffer.byteLength(chunk)` in `req.on('data')`, enforce maximums, and sanitize global `catch` blocks to prevent leaking error stack traces or internals.
