## 2026-11-11 - Request Stream Destruction Memory Leak
**Vulnerability:** Memory leak and Denial of Service risk when rejecting large payloads.
**Learning:** When destroying a Node.js request stream early (req.destroy()) while parsing inside a Promise, if the Promise is not rejected, it will pend indefinitely.
**Prevention:** Always explicitly reject the Promise before destroying the request and add 'if (req.destroyed) return;' in the end handler.
