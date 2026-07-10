## 2024-07-10 - Fix Node.js Promise memory leak on early request destroy
**Vulnerability:** Denying large payloads via req.destroy() inside a Promise without resolving/rejecting leads to memory leaks.
**Learning:** If a request stream is destroyed early, the `end` event will not fire. If parsing is wrapped in a Promise, the Promise will remain pending indefinitely, causing a memory leak on the server side.
**Prevention:** Always explicitly call `reject` or `resolve` before or alongside `req.destroy()`, and add a check for `req.destroyed` in the `end` event handler.
