// GenPay backend — zero external dependencies (Node built-ins only).
//
// Keeps the Razorpay Key Secret and the NVIDIA NIM key OFF the device. The
// Flutter app talks only to this server; secrets live in server/.env.
//
// Endpoints:
//   GET  /health              → { ok: true }
//   POST /razorpay/order      → { order_id, amount, currency, key_id }
//   POST /razorpay/verify     → { valid: bool }
//   POST /ai/chat             → { text }   (proxies to NVIDIA NIM)
//
// Run:  node server/server.js   (reads server/.env)

const http = require('http');
const https = require('https');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// ── Minimal .env loader (no dotenv dep) ──────────────────────────────────────
function loadEnv() {
  const file = path.join(__dirname, '.env');
  const env = {};
  try {
    for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/i);
      if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch (_) {
    console.warn('⚠  server/.env not found — using process.env only');
  }
  return { ...env, ...process.env };
}
const ENV = loadEnv();

const PORT = parseInt(ENV.PORT || '8080', 10);
const RZP_KEY_ID = ENV.RAZORPAY_KEY_ID || '';
const RZP_SECRET = ENV.RAZORPAY_KEY_SECRET || '';
const NIM_KEY = ENV.NVIDIA_API_KEY || '';
const NIM_BASE = ENV.NVIDIA_API_BASE || 'https://integrate.api.nvidia.com/v1';
const NIM_MODEL = ENV.NVIDIA_MODEL || 'meta/llama-3.1-8b-instruct';

// ── Helpers ──────────────────────────────────────────────────────────────────
function httpsJson(urlStr, { method = 'POST', headers = {}, body } = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlStr);
    const payload = body ? JSON.stringify(body) : null;
    const req = https.request(
      {
        hostname: url.hostname,
        path: url.pathname + url.search,
        method,
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json',
          ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          let parsed = null;
          try { parsed = JSON.parse(data); } catch (_) { parsed = data; }
          resolve({ status: res.statusCode, body: parsed });
        });
      }
    );
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

function send(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (c) => {
      data += c;
      if (data.length > 1024 * 1024) {
        req.destroy();
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      try { resolve(data ? JSON.parse(data) : {}); }
      catch (_) { resolve({}); }
    });
    req.on('error', reject);
  });
}

// ── Razorpay: create order ───────────────────────────────────────────────────
async function createOrder(amountRupees, receipt) {
  const auth = 'Basic ' + Buffer.from(`${RZP_KEY_ID}:${RZP_SECRET}`).toString('base64');
  const { status, body } = await httpsJson('https://api.razorpay.com/v1/orders', {
    headers: { Authorization: auth },
    body: {
      amount: Math.round(amountRupees * 100), // paise
      currency: 'INR',
      receipt: receipt || `genpay_${Date.now()}`,
      payment_capture: 1,
    },
  });
  if (status !== 200) throw new Error(`Razorpay order failed: ${JSON.stringify(body)}`);
  return body; // { id, amount, currency, ... }
}

// ── Razorpay: verify checkout signature ──────────────────────────────────────
// signature = HMAC_SHA256(order_id + "|" + payment_id, key_secret)
function verifySignature(orderId, paymentId, signature) {
  const expected = crypto
    .createHmac('sha256', RZP_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
  // constant-time compare
  const a = Buffer.from(expected);
  const b = Buffer.from(signature || '');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// ── NVIDIA NIM proxy ─────────────────────────────────────────────────────────
async function nimChat(prompt, { temperature = 0.3, maxTokens = 600 } = {}) {
  const { status, body } = await httpsJson(`${NIM_BASE}/chat/completions`, {
    headers: { Authorization: `Bearer ${NIM_KEY}` },
    body: {
      model: NIM_MODEL,
      messages: [{ role: 'user', content: prompt }],
      temperature,
      max_tokens: maxTokens,
    },
  });
  if (status !== 200) throw new Error(`NIM error ${status}: ${JSON.stringify(body)}`);
  return body?.choices?.[0]?.message?.content ?? '';
}

// ── Router ───────────────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, {});

  try {
    if (req.method === 'GET' && req.url === '/health') {
      return send(res, 200, {
        ok: true,
        razorpay: Boolean(RZP_KEY_ID && RZP_SECRET),
        nim: Boolean(NIM_KEY),
        model: NIM_MODEL,
      });
    }

    if (req.method === 'POST' && req.url === '/razorpay/order') {
      const { amount, receipt } = await readBody(req);
      if (!amount || amount <= 0) return send(res, 400, { error: 'amount required' });
      const order = await createOrder(amount, receipt);
      return send(res, 200, {
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        key_id: RZP_KEY_ID,
      });
    }

    if (req.method === 'POST' && req.url === '/razorpay/verify') {
      const { order_id, payment_id, signature } = await readBody(req);
      const valid = verifySignature(order_id, payment_id, signature);
      return send(res, 200, { valid });
    }

    if (req.method === 'POST' && req.url === '/ai/chat') {
      const { prompt, temperature, maxTokens } = await readBody(req);
      if (!prompt) return send(res, 400, { error: 'prompt required' });
      const text = await nimChat(prompt, { temperature, maxTokens });
      return send(res, 200, { text });
    }

    return send(res, 404, { error: 'not found' });
  } catch (e) {
    console.error('✗', e.message);
    const isPayloadError = e.message === 'Payload too large';
    return send(res, isPayloadError ? 413 : 500, {
      error: isPayloadError ? e.message : 'Internal Server Error'
    });
  }
});

server.listen(PORT, () => {
  console.log(`GenPay backend on :${PORT}`);
  console.log(`  razorpay: ${RZP_KEY_ID ? 'configured' : 'MISSING'} | nim: ${NIM_KEY ? 'configured' : 'MISSING'} (${NIM_MODEL})`);
});
