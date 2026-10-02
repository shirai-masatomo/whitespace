const fs = require('node:fs');
const assert = require('node:assert/strict');
const { replay } = require('../src/sim.js');

if (!process.argv[2]) {
  console.error('Usage: node tools/replay.cjs <observation.json>');
  process.exit(1);
}
const record = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (record.version !== 1) throw new Error('Unsupported observation version');
const actual = replay(record).snapshot();
assert.deepEqual(actual, record, 'Replay differs from the recorded state');
console.log(JSON.stringify({ replay: 'exact', seed: actual.seed, seconds: actual.seconds,
  result: actual.result, counts: actual.counts, stats: actual.stats }, null, 2));
