## 2024-05-24 - Zero-Dependency Payload Size DoS and Info Leak

**Vulnerability:** The zero-dependency Node.js backend lacked a body parsing payload limit, allowing an attacker to DoS the server with excessive RAM allocation on POST routes. Error handlers leaked raw exception messages.
**Learning:** When intentionally avoiding Express or body-parser, native raw event handling `req.on('data')` must manually implement length checks via `Buffer.byteLength(chunk)` before concatenating to avoid memory exhaustion DoS vectors.
**Prevention:** Implement `req.pause()`, clear the underlying socket with `req.destroy()`, and set generic `Internal server error` handlers to avoid Information Disclosure while keeping the server up under load.
