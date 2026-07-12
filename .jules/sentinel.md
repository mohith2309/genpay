## 2024-10-24 - DoS vulnerability via unbound payload size
**Vulnerability:** Node.js server lacks request payload size limits, allowing potential Denial of Service by sending large payloads.
**Learning:** When terminating requests early using `req.destroy()` during a stream consumption inside a Promise, we must reject the promise explicitly and check `req.destroyed` in the `end` event handler to avoid indefinitely pending promises causing memory leaks. Also, `res.headersSent` must be checked before sending custom responses to prevent "Cannot set headers after they are sent" errors.
**Prevention:** Implement maximum size checks using `Buffer.byteLength()` inside the `data` chunk event handler, pause request parsing, set `Connection: close`, and safely destroy the request socket.
