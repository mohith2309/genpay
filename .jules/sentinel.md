## 2024-05-30 - Prevent Information Disclosure & Payload Limiting in Node Built-in HTTP Server
**Vulnerability:** Node.js built-in HTTP server lacked payload size limits (DoS risk) and leaked error messages in 500 responses (Information Disclosure).
**Learning:** Using built-ins requires manually handling stream termination to deliver a 413 before connection closes. The global catch handler shouldn't directly return `e.message`.
**Prevention:** Added an explicit 1MB limit check in the data chunk handler, pausing the stream, responding with 413, and destroying the connection. Masked server errors with a generic "Internal server error" string.
