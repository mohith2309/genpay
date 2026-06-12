## 2026-06-12 - Missing Payload Limit and Information Leakage in Custom Backend Router
**Vulnerability:** The custom Node.js backend lacked payload size validation, allowing potential DoS via memory exhaustion. Additionally, the global error handler passed unfiltered error messages to the client, leaking internal API and Razorpay details.
**Learning:** When building zero-dependency Node.js servers, foundational protections like payload limiting and safe error reporting must be manually implemented; they are not free as they are in frameworks like Express.
**Prevention:** Always accumulate incoming body stream bytes and check `Buffer.byteLength()` against a sane limit. Explicitly catch generic errors and return a safe '500 Internal Server Error' instead of `e.message`.
