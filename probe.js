const dns = require('dns');
const names = process.argv.slice(2);
(async () => {
  for (const n of names) {
    const r = await new Promise(res => dns.lookup(n, { family: 4 }, (e, a) => res(e ? 'MISS' : a)));
    console.log(`    query ${JSON.stringify(n).padEnd(20)} node dns.lookup=${r}`);
  }
})();
