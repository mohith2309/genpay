## 2024-05-18 - Prevent memory exhaustion DoS and info leaks in Node.js backend
**Vulnerability:** `readBody` function allowed unlimited payload sizes, opening the door for Denial of Service via memory exhaustion (CWE-400). The global error handler exposed raw error messages (`e.message`) to the client, potentially leaking API keys or internal paths (CWE-209).
**Learning:** Even built-in basic HTTP server implementations in Node.js need strict payload caps and error message sanitization.
**Prevention:** Always cap incoming payloads (e.g., 1MB) and use `req.destroy()` to safely close connections from abusive clients. Never forward internal error messages directly to the response body; log them internally and return generic messages.
