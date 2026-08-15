const https = require('https');

const KEY = process.env.YVP_KEY || process.env.YVP_API_KEY;
if (!KEY) {
  console.error('Missing API key. Set YVP_KEY or YVP_API_KEY in your environment.');
  process.exit(1);
}

const endpoints = [
  'https://developers.youversion.com/v1/bibles',
  'https://developers.youversion.com/api/v1/bibles',
  'https://api.youversion.com/v1/bibles',
  'https://platform.youversion.com/v1/bibles',
  'https://youversion.com/v1/bibles'
];

function fetchEndpoint(url) {
  return new Promise((resolve) => {
    const req = https.get(url, {
      headers: {
        'X-YVP-App-Key': KEY,
        'Accept': 'application/json',
        'User-Agent': 'node-try-endpoints/1.0'
      },
      timeout: 15000
    }, (res) => {
      let raw = '';
      res.on('data', (c) => (raw += c));
      res.on('end', () => {
        resolve({ url, statusCode: res.statusCode, headers: res.headers, body: raw });
      });
    });
    req.on('error', (err) => resolve({ url, error: err.message }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ url, error: 'timeout' });
    });
  });
}

(async () => {
  for (const url of endpoints) {
    console.error('\n=== probing', url, '===');
    const r = await fetchEndpoint(url);
    if (r.error) {
      console.error('Error:', r.error);
      continue;
    }
    console.error('Status:', r.statusCode);
    console.error('Content-Type:', r.headers['content-type']);
    const bodySnippet = (r.body || '').slice(0, 2000);
    if (bodySnippet.trim().startsWith('<')) {
      console.error('Body (HTML snippet):');
      console.error(bodySnippet);
    } else {
      try {
        const json = JSON.parse(r.body);
        console.error('JSON response keys:', Object.keys(json).slice(0,10));
        if (json.data && Array.isArray(json.data)) {
          console.log(JSON.stringify(json.data.filter(b => {
            const name = (b.name||'').toLowerCase();
            const lang = (b.language && (b.language.name||b.language.code) || '').toLowerCase();
            return /nasb|nasv|oromo|oromifa|afaan|om(-|_)?et|\bom\b|\borm\b/.test(name + ' ' + lang);
          }), null, 2));
        } else {
          console.log('Full JSON (truncated):', JSON.stringify(json).slice(0,2000));
        }
      } catch (e) {
        console.error('Non-JSON body (first 2000 chars):');
        console.error(bodySnippet);
      }
    }
  }
})();
