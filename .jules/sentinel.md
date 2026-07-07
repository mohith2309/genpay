## 2024-05-24 - Node.js Server Vulnerabilities
**Vulnerability:** DoS via unlimited payload size and Information Disclosure via raw error messages.
**Learning:** Streams need explicit management (req.pause(), req.destroy(), and reject()) to avoid resource exhaustion and hanging promises. Global error handlers shouldn't leak `e.message`.
**Prevention:** Always enforce a max payload limit with Buffer.byteLength when reading streams and return generic string errors like "Internal server error" for 500 responses.
