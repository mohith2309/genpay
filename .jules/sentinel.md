## 2026-07-12 - Prevent "Headers already sent" crashes when rejecting payloads early
**Vulnerability:** Node.js stream payload limits using `req.destroy()` inside `res.end()` callbacks can race with global error handlers in simple servers, leading to `Error [ERR_HTTP_HEADERS_SENT]` and server crashes.
**Learning:** If a custom body parser responds with 413 and destroys the request, the upper-level request handlers (or global `catch` blocks) might still try to send a 500 error if they catch the stream destruction error, crashing the server because headers were already dispatched.
**Prevention:** Always check `if (res.headersSent) return;` in custom response/send helper functions to ensure secondary errors don't attempt to overwrite an already finalized HTTP response.
