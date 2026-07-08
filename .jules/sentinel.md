## 2026-07-08 - Payload Stream Destruction in Node.js
**Vulnerability:** Unbounded request payload sizes could lead to DoS out-of-memory crashes, while attempting to limit sizes without properly cleaning up Streams led to hanging requests.
**Learning:** Destroying a Node.js request stream `req.destroy()` while inside a Promise requires explicitly rejecting/resolving the Promise. Without this, the `end` event never fires and the Promise stays pending indefinitely, causing a memory leak.
**Prevention:** Always add `reject(new Error(...))` alongside `req.destroy()` and check `if (req.destroyed) return;` inside `req.on('end')` to safely abort parsing.
