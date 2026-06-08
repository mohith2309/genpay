## 2026-06-08 - [Information Leakage and DoS in custom HTTP server]
**Vulnerability:** Custom `readBody` function lacked payload size limits, allowing potential OOM DoS attacks. Global error handler leaked internal API errors (`e.message`) directly to the client.
**Learning:** Zero-dependency Node.js HTTP servers require manual implementation of basic protections (like payload limits) that frameworks like Express handle automatically.
**Prevention:** Always implement max payload checks when buffering streams (`req.on('data')`) and ensure global catch blocks return generic errors (e.g. 'Internal Server Error') instead of raw exception messages.
