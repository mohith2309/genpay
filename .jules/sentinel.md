## 2026-06-09 - [Missing Payload Limit and Sanitization]
**Vulnerability:** readBody lacked payload size limits (DoS risk) and error handler leaked internal error messages.
**Learning:** Node.js native server requests do not limit payload size by default, and top-level try/catch handlers can easily leak upstream errors.
**Prevention:** Implement payload size limits during 'data' event stream parsing and enforce sanitizing specific 500 error messages while passing down expected HTTP errors.
