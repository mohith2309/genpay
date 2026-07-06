## 2026-07-06 - Prevent Node.js Memory Leaks with req.destroy()
**Vulnerability:** DoS via memory exhaustion (Missing payload limit and memory leak on early request destruction).
**Learning:** When destroying a Node.js request stream early (`req.destroy()`) inside a Promise (like `readBody`), if the Promise is not explicitly resolved or rejected, the `end` event will not fire, and the Promise will pend indefinitely, causing a memory leak.
**Prevention:** Implement a byte-length payload limit using `Buffer.byteLength(chunk)`. When limits are exceeded, pause the stream, send a 413 response with `Connection: close`, destroy the request within `res.end`, and ensure the Promise is explicitly rejected. Also add `if (req.destroyed) return;` to the `end` event handler.
