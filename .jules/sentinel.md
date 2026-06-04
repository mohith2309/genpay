# Sentinel's Journal - GenPay Security

## 2025-05-14 - Backend Security Hardening
**Vulnerability:** Multiple vulnerabilities in `server/server.js` including Information Leakage (exposing upstream API error bodies to the client), Denial of Service (no request body size limit), and potential resource exhaustion (missing timeouts on outgoing requests).
**Learning:** Minimalist Node.js servers without middleware (like `body-parser` or `express`) require manual implementation of basic security controls that are often taken for granted.
**Prevention:**
1. Always implement request body size limits in `readBody`.
2. Sanitize error messages: log details server-side, but return generic messages to the client.
3. Set explicit timeouts on all outgoing HTTPS requests.
4. Ensure security-critical functions (like signature verification) fail securely if configuration is missing.
