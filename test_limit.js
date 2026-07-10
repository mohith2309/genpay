const http = require('http');

function send(res, status, obj) {
  if (res.headersSent) return;
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json'
  });
  res.end(body);
}

function readBody(req, res) {
  return new Promise((resolve, reject) => {
    let data = '';
    let size = 0;
    const MAX_SIZE = 100; // very small limit
    req.on('data', (c) => {
      size += Buffer.byteLength(c);
      if (size > MAX_SIZE) {
        req.pause();
        res.writeHead(413, { 'Connection': 'close', 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Payload Too Large' }), () => {
          req.destroy();
        });
        reject(new Error('Payload Too Large'));
        return;
      }
      data += c;
    });
    req.on('end', () => {
      if (req.destroyed) return;
      try { resolve(data ? JSON.parse(data) : {}); }
      catch (_) { resolve({}); }
    });
  });
}

const server = http.createServer(async (req, res) => {
  try {
    const body = await readBody(req, res);
    send(res, 200, { ok: true, body });
  } catch(e) {
    send(res, 500, { error: 'Internal server error' });
  }
});
server.listen(3000, () => console.log('started'));
