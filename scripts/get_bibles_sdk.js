const { ApiClient } = require('@youversion/platform-core');

const KEY = process.env.YVP_KEY || process.env.YVP_API_KEY;
if (!KEY) {
  console.error('Missing API key. Set YVP_KEY or YVP_API_KEY in your environment.');
  process.exit(1);
}

const util = require('util');
const client = new ApiClient({ appKey: KEY });

console.error('Client keys:', Object.keys(client));
console.error('client.bibles:', typeof client.bibles);

async function listBibles() {
  try {
    let res;
    if (client.bibles && typeof client.bibles.list === 'function') {
      res = await client.bibles.list();
    } else if (typeof client.request === 'function') {
      try {
        res = await client.request('/v1/bibles');
      } catch (e) {
        res = await client.request({ method: 'GET', path: '/v1/bibles' });
      }
    } else {
      throw new Error('Unknown SDK client shape; available keys: ' + util.inspect(Object.keys(client)));
    }

    console.error('Raw response from SDK:', util.inspect(res, { depth: 2 }));
    const bibles = (res && (res.data || res.bibles || res.body)) || [];

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
    console.error('SDK request failed:', err && err.message ? err.message : err);
    process.exit(2);
  }
}

listBibles();
