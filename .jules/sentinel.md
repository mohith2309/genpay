## 2023-10-27 - Implement Node.js Payload Limits & Sanitize Errors
**Vulnerability:** Missing request body payload limits and unsanitized server error messages returning upstream API errors to clients in `server/server.js`.
**Learning:** Node's HTTP module built-in `on('data')` handler can consume unbounded memory if no limits are manually enforced, leading to DoS. Returning `e.message` in Catch blocks blindly leaks sensitive data.
**Prevention:** Always check `Buffer.byteLength(data)` against a predefined threshold (e.g. 1MB) and call `req.destroy()` to drop large connections. Send generic "Internal Server Error" messages to clients by default, avoiding `e.message` exposure unless manually whitelisted.
