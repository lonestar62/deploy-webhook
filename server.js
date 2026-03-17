const express = require('express');
const crypto = require('crypto');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 9101;
const WEBHOOK_SECRET = (process.env.WEBHOOK_SECRET || '').trim();

app.use((req, res, next) => {
  let data = [];
  req.on('data', chunk => data.push(chunk));
  req.on('end', () => {
    req.rawBody = Buffer.concat(data);
    try {
      req.body = JSON.parse(req.rawBody.toString());
    } catch {
      req.body = {};
    }
    next();
  });
});

function verifySignature(req) {
  if (!WEBHOOK_SECRET) return true;
  const sig = req.headers['x-hub-signature-256'];
  if (!sig) return false;
  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  hmac.update(req.rawBody);
  const expected = 'sha256=' + hmac.digest('hex');
  try {
    return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
  } catch {
    return false;
  }
}

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'deploy-webhook' });
});

app.post('/webhook', (req, res) => {
  if (!verifySignature(req)) {
    console.error('[webhook] Invalid signature');
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const payload = req.body;
  const ref = payload.ref || '';
  const repoName = (payload.repository && payload.repository.name) || '';

  console.log(`[webhook] ref=${ref} repo=${repoName}`);

  // Only deploy on push to main
  if (ref !== 'refs/heads/main') {
    return res.status(200).json({ status: 'skipped', reason: 'not main branch' });
  }

  if (!repoName) {
    return res.status(400).json({ error: 'No repository name in payload' });
  }

  const scriptPath = path.join(__dirname, 'scripts', `${repoName}.sh`);
  if (!fs.existsSync(scriptPath)) {
    console.error(`[webhook] No deploy script for repo: ${repoName}`);
    return res.status(404).json({ error: `No deploy script for repo: ${repoName}` });
  }

  res.status(202).json({ status: 'deploying', repo: repoName });

  // Run deploy script asynchronously
  setImmediate(() => {
    try {
      console.log(`[deploy] Starting deploy for ${repoName}`);
      execSync(`bash ${scriptPath}`, { stdio: 'inherit', timeout: 300000 });
      console.log(`[deploy] Completed deploy for ${repoName}`);
    } catch (err) {
      console.error(`[deploy] Failed deploy for ${repoName}: ${err.message}`);
    }
  });
});

app.listen(PORT, () => {
  console.log(`deploy-webhook listening on port ${PORT}`);
});
