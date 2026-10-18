const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const c = require('../docs/config.js');

assert.equal(c.parseAmount('1.5m'), 1500000);
assert.equal(c.parseAmount('1,024'), 1024);
assert.equal(c.parseAmount('1.2345k'), null);
assert.equal(c.parseAmount('9007199254740992'), null);
assert.equal(c.parseAmount('0'), 0);
const entries = [
  c.makeEntry('Sodium Hydroxide Dust', '512', '256'),
  c.makeEntry('P-507', '4k', '1k', '', '8k', 'fluids'),
  c.makeEntry('P-507', '', '1', 'p507'),
  c.makeEntry('Zero low', '0', '2', '', '10'),
  c.makeEntry('64k Cell -- "quoted" \\ name', '10k', '64'),
  {...c.makeEntry('Disabled', '10', '2', '', '20'), enabled: false},
  c.makeEntry('Always craft', '0', '32')
];
const text = c.formatConfigFile(entries);
assert(!text.includes('10k'));
assert(text.includes('low = 4000, target = 8000, batch = 1000'));
assert.deepEqual(c.importText(text), [...entries.filter(e => e.block === 'items'), ...entries.filter(e => e.block === 'fluids')]);
assert.deepEqual(c.cleanEntries(JSON.parse(JSON.stringify(entries))), entries);
assert.deepEqual(c.cleanEntry({Name: 'Old', Threshold: 50, Count: 10, Fluid: '', Enabled: false}),
  {...c.makeEntry('Old', '50', '10'), enabled: false});
assert.equal(c.importText('["Short"] = {10k, 1k},')[0].threshold, 10000);
assert.equal(c.importText('["Multi"] = {\n low = 10,\n target = 20,\n batch = 5,\n},')[0].target, 20);
assert.equal(c.importText('["Override"] = {low = 1, target = 2, batch = 1, fluidName = "x"},')[0].fluid, 'x');
const quotedName = c.cleanEntry({name: '"Quoted name"', count: 1, threshold: 10});
assert.equal(c.importText(c.formatConfigFile([quotedName]))[0].name, quotedName.name);
const timed = c.makeEntry('Fast Fluid', '100', '40', 'fast', '200', 'fluids', false, '0.5');
assert.equal(timed.refillInterval, 0.5);
assert(c.formatEntry(timed).includes('refillInterval = 0.5'));
assert.deepEqual(c.importText(c.formatConfigFile([timed])), [timed]);
assert.deepEqual(c.cleanEntry(JSON.parse(JSON.stringify(timed))), timed);
const tinyInterval = c.makeEntry('Small interval', '10', '1', '', '20', 'items', false, '0.0000001');
assert.deepEqual(c.importText(c.formatConfigFile([tinyInterval])), [tinyInterval]);
assert.equal(c.cleanEntry({Name: 'Old', Threshold: 10, Count: 5}).refillInterval, null);
assert.equal(c.cleanEntry({Name: 'Fast', Threshold: 10, Target: 20, Count: 5, RefillInterval: 2}).refillInterval, 2);
for (const bad of ['0', '-1', 'Infinity', 'NaN', '2k', '']) {
  if (bad !== '') assert.throws(() => c.makeEntry('Fast', '10', '5', '', '20', 'items', false, bad));
}
assert.throws(() => c.makeEntry('Fast', '10', '5', '', '', 'items', false, '2'));
assert.throws(() => c.importText('["Bad timer"] = {low = 10, target = 20, batch = 5, refillInterval = 0}'));
for (const invalid of [
  '["Bad"] = {low = 10, target = 5, batch = 1}',
  '["Bad"] = {low = 10, batch = 1}',
  '["Bad"] = {10, 0}',
  '["Bad"] = {10, 1, ignored = 3}',
  '["Bad"] = {math.huge, 1}',
  '["Bad"] = {10, 1}\n["Bad"] = {20, 1}',
  '["Bad"] = {10, 1}\ncfg.other = {}',
  '["Bad"] = {10, 1}\n["Broken"] = {'
]) assert.throws(() => c.importText(invalid), undefined, invalid);
for (const input of [text, 'x'.repeat(3500), '😀'.repeat(2501), 'line\n'.repeat(300)]) {
  const parts = c.splitParts(input, 1000);
  assert.equal(parts.join(''), input);
  assert(parts.every(p => Array.from(p).length <= 1000));
}
assert.throws(() => c.cleanEntries([{Name: 'Invalid', Count: 0}]));
assert.throws(() => c.makeEntry('Test', '100', '10', '', '50'));
const html = fs.readFileSync(require.resolve('../docs/index.html'), 'utf8');
assert(!html.includes('tokens truncated'), 'editor source must not contain truncated transfer output');
assert(html.includes('</style>') && html.includes('<body>') && html.includes('id="entry-form"'));
new vm.Script(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
if (process.env.EDITOR_CONFIG_OUTPUT) fs.writeFileSync(process.env.EDITOR_CONFIG_OUTPUT, text);
console.log('PASS: editor Lua round trips, refill targets, legacy backups, invalid imports, plain numbers and paste chunks');
