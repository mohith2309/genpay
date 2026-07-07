const http = require('http');

async function testPayloadLimit() {
  return new Promise((resolve) => {
    const req = http.request('http://localhost:8080/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        console.log('Payload Test Status:', res.statusCode);
        console.log('Payload Test Response:', data);
        resolve();
      });
    });

    req.on('error', (e) => {
      console.log('Request error:', e.message);
      resolve();
    });

    // Generate valid JSON that is large
    // {"prompt":"aaa..."}
    const chunk = "a".repeat(1024 * 1024); // 1MB
    req.write('{"prompt":"');
    req.write(chunk);
    req.write('"}');
    req.end();
  });
}

async function testErrorDisclosure() {
  return new Promise((resolve) => {
    // Sending bad JSON to trigger an error, or sending invalid request
    const req = http.request('http://localhost:8080/razorpay/order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        console.log('Error Test Status:', res.statusCode);
        console.log('Error Test Response:', data);
        resolve();
      });
    });

    // Valid JSON but without amount, which will just return 400.
    // To trigger 500, we can trigger createOrder which will fail due to missing keys (if not configured).
    req.write('{"amount": 100}');
    req.end();
  });
}

async function run() {
  await testPayloadLimit();
  await testErrorDisclosure();
}

run();
