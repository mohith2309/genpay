const http = require('http');

const req = http.request({
  hostname: 'localhost',
  port: 8080,
  path: '/ai/chat',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
}, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  res.on('data', (chunk) => {
    console.log(`BODY: ${chunk}`);
  });
  process.exit(0);
});

req.on('error', (e) => {
  console.error(`problem with request: ${e.message}`);
});

const chunk = 'a'.repeat(1024 * 1024);
req.write(chunk);
req.write(chunk);
req.end();
