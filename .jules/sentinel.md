## 2024-05-24 - Fix Denial of Service and Information Disclosure in Node Backend
**Vulnerability:** Node backend allowed unbounded request bodies, creating a Denial of Service risk, and generic 500 errors exposed internal error messages (e.g., `e.message`).
**Learning:** In a pure Node.js backend using `req.on('data')`, payload limits must be explicitly enforced by counting bytes, pausing the request, sending a 413 status, and destroying the request stream to prevent memory exhaustion and hanging connections.
**Prevention:** Always enforce a maximum byte limit on incoming request payloads and return generic error messages for unhandled exceptions in the global scope.
