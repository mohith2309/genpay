## 2024-07-09 - Node.js Custom Server DoS & Info Disclosure
**Vulnerability:** Unbounded memory buffering in `readBody` causing DoS (Payload Too Large), and `catch(e)` leaking sensitive error details.
**Learning:** Custom Node.js servers handling streams without external frameworks (like Express) often forget to limit payload sizes and explicitly destroy rejected streams correctly, leading to both memory leaks and DoS. Global error handlers without static messages leak implementation details.
**Prevention:** Always use `Buffer.byteLength(chunk)` with a maximum size threshold (e.g., 1MB) for incoming HTTP streams. Close connections securely via `req.destroy()` after sending 413, and enforce generic 500 responses.
