## 2026-07-07 - DoS via Memory Exhaustion in Custom Express-like Router
**Vulnerability:** Node.js streams do not enforce size limits by default. `req.on('data')` accumulated strings unbounded, allowing memory exhaustion (DoS).
**Learning:** In a custom zero-dependency Node router without external body parsers, developers must manually keep track of byte lengths using `Buffer.byteLength(chunk)` and halt streams correctly via `req.pause()` and `req.destroy()`.
**Prevention:** Always enforce a hard `MAX_SIZE` limit on incoming request bodies, explicitly rejecting the promise if destroyed to avoid dangling asynchronous handlers.
