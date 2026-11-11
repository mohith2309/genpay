## 2026-11-11 - Prevent memory leak during payload rejection
**Vulnerability:** Node.js streams pend indefinitely when destroyed inside a Promise without explicitly rejecting, causing memory leaks (DoS risk).
**Learning:** If a payload exceeds the limit and we invoke req.destroy(), the req.on('end') event will not fire. The enclosing Promise must be explicitly rejected, and the end event handler needs a state check (if (req.destroyed) return;).
**Prevention:** Always explicitly call reject() when calling req.destroy() in a Promise, and add state checks in end handlers to avoid race conditions.
