const https = require('https');

const KEY = process.env.YVP_KEY || process.env.YVP_API_KEY;
if (!KEY) {
  console.error('Missing API key. Set YVP_KEY or YVP_API_KEY in your environment.');
  process.exit(1);
}

const URL = 'https://developers.youversion.com/v1/bibles';

function fetchRaw(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers }, (res) => {
      let raw = '';
      res.on('data', (c) => (raw += c));
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: raw }));
    });
    req.on('error', reject);
  });
}

function tryParseJson(text) {
  try { return JSON.parse(text); } catch (e) { return null; }
}

(async () => {
  try {
    const { statusCode, headers, body } = await fetchRaw(URL, {
      'X-YVP-App-Key': KEY,
      'Accept': 'application/json',
      'User-Agent': 'node-get-bibles-script/1.0'
    });

    console.error('Status:', statusCode);
    console.error('Headers:', headers);

    const json = tryParseJson(body);
    if (!json) {
      console.error('Response is not JSON. First 2000 chars of body:');
      console.error(body.slice(0, 2000));
      process.exit(2);
    }

    const bibles = Array.isArray(json.data) ? json.data : (json.bibles || []);

    const matches = bibles.filter((b) => {
      const name = (b.name || '').toLowerCase();
      const lang = (b.language && (b.language.name || b.language.code) || '').toLowerCase();
      if (/nasb|nasv/.test(name)) return true;
      if (/oromo|oromifa|afaan/.test(name)) return true;
      if (['om', 'orm', 'om-et'].includes((b.language && b.language.code || '').toLowerCase())) return true;
      if (/oromo|oromifa|afaan/.test(lang)) return true;
      return false;
    });

    console.log(JSON.stringify(matches, null, 2));
  } catch (err) {
    console.error('Request failed:', err.message || err);
    process.exit(3);
  }
})();
