// Config data helpers shared by the browser editor and Node regression tests.
// Adapted from Willshaper/Level-Maintainer's Config List editor.
'use strict';
const EXPONENT = {k: 3, m: 6, g: 9, b: 9, t: 12};
function parseAmount(text, luaOnly = false) {
  const t = String(text).replace(/\s/g, '').toLowerCase();
  const m = t.match(luaOnly ? /^(\d+)(?:\.(\d+))?([kmgbt])$/ : /^(\d+)(?:[.,](\d+))?([kmgbt])$/);
  let n;
  if (m) {
    const e = EXPONENT[m[3]], fraction = m[2] || '';
    if (/[^0]/.test(fraction.slice(e))) return null;
    n = Number(m[1] + fraction.slice(0, e).padEnd(e, '0'));
  } else if (/^\d+$/.test(t)) n = Number(t);
  else if (!luaOnly && /^\d{1,3}([,._]\d{3})+$/.test(t)) n = Number(t.replace(/[,._]/g, ''));
  else return null;
  return Number.isSafeInteger(n) ? n : null;
}
function formatAmount(n) {
  for (const [suffix, unit] of [['t', 1e12], ['g', 1e9], ['m', 1e6], ['k', 1e3]]) {
    if (n >= unit && n % (unit / 100) === 0) return String(n / unit) + suffix;
  }
  return String(n);
}
function withSeparators(n) { return n.toLocaleString('en-US'); }
function stripQuotes(text) { return String(text).trim().replace(/^["“”„]+|["“”„]+$/g, '').trim(); }
function makeEntry(name, maintain, batch, fluid = '', target = '', block = 'items', literalName = false) {
  const clean = literalName ? String(name) : stripQuotes(name);
  if (!clean || /[\x00-\x1f\x7f]/.test(clean)) throw new Error('Enter a name without control characters.');
  const threshold = String(maintain).trim() === '' ? 0 : parseAmount(maintain);
  const count = parseAmount(batch);
  const upper = String(target).trim() === '' ? null : parseAmount(target);
  if (threshold === null) throw new Error('Maintain / Low must be a nonnegative whole number.');
  if (count === null || count === 0) throw new Error('Batch must be a whole number above 0.');
  if (String(target).trim() !== '' && (upper === null || upper < threshold)) throw new Error('Target must be a whole number at least Low.');
  if (!['items', 'fluids'].includes(block)) throw new Error('Entry type must be items or fluids.');
  const registry = String(fluid).trim();
  if (/[\x00-\x1f\x7f]/.test(registry)) throw new Error('Fluid registry name contains a control character.');
  return {name: clean, threshold, count, target: upper, fluid: registry, block, enabled: true};
}
function luaString(s) { return '"' + s.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"'; }
function formatEntry(e) {
  // Numeric shorthand is a UI convenience, never a Lua literal.
  const extra = e.fluid ? ', ' + (e.target == null ? '' : 'fluidName = ') + luaString(e.fluid) : '';
  const values = e.target == null
    ? `${e.threshold === 0 ? 'nil' : e.threshold}, ${e.count}${extra}`
    : `low = ${e.threshold}, target = ${e.target}, batch = ${e.count}${extra}`;
  return `${e.enabled === false ? '--' : ''}    [${luaString(e.name)}] = {${values}},`;
}
function formatLines(entries) { return entries.map(formatEntry).join('\n'); }
function formatSections(entries) {
  let out = '';
  for (const block of ['items', 'fluids']) {
    out += `cfg["${block}"] = {\n${formatLines(entries.filter(e => (e.block || 'items') === block))}\n}\n\n`;
  }
  return out;
}
function formatConfigFile(entries) {
  return 'local cfg = {}\n\n-- Generated config: fluid amounts are in mB.\n' + formatSections(entries) + 'return cfg\n';
}
function cleanEntry(raw) {
  if (!raw || typeof raw !== 'object') throw new Error('Invalid backup entry.');
  const e = makeEntry(raw.name ?? raw.Name ?? '', raw.threshold ?? raw.Threshold ?? 0,
    raw.count ?? raw.Count ?? '', raw.fluid ?? raw.Fluid ?? '', raw.target ?? raw.Target ?? '', raw.block ?? raw.Block ?? 'items', true);
  e.enabled = (raw.enabled ?? raw.Enabled) !== false;
  return e;
}
function cleanEntries(list) {
  if (!Array.isArray(list)) throw new Error('Expected a list of entries.');
  const entries = list.map(cleanEntry), keys = new Set();
  for (const e of entries) {
    const key = JSON.stringify([e.block, e.name]);
    if (keys.has(key)) throw new Error(`Duplicate ${e.block} entry: ${e.name}`);
    keys.add(key);
  }
  return entries;
}
function decodeLuaString(token) {
  if (!/^"(?:[^"\\]|\\["\\])*"$/.test(token)) throw new Error('Only quoted names with escaped quotes or backslashes are supported.');
  return token.slice(1, -1).replace(/\\(["\\])/g, '$1');
}
function parseFields(body) {
  const fields = [];
  const token = /\s*(?:(\w+)\s*=\s*)?("(?:[^"\\]|\\.)*"|nil|\d+(?:\.\d+)?[kmgbt]?)(\s*[,;]\s*|\s*$)/igy;
  let position = 0;
  while (position < body.length && body.slice(position).trim()) {
    token.lastIndex = position;
    const m = token.exec(body);
    if (!m) throw new Error('Unsupported value or expression in config entry.');
    fields.push({key: m[1], value: m[2]});
    position = token.lastIndex;
  }
  const named = fields.some(f => f.key);
  if (named && fields.some(f => !f.key)) throw new Error('Mixed positional and named entries are not supported.');
  const values = {};
  const keys = named ? ['low', 'target', 'batch', 'fluidName'] : ['low', 'batch', 'fluidName'];
  fields.forEach((f, i) => {
    const key = named ? f.key : keys[i];
    if (!keys.includes(key) || Object.hasOwn(values, key)) throw new Error('Unknown or duplicate entry field.');
    values[key] = f.value;
  });
  if (!values.batch) throw new Error('Entry is missing its batch amount.');
  if (named && (!values.low || !values.target)) throw new Error('Named entries require low, target and batch.');
  const low = values.low === 'nil' || values.low == null ? '' : values.low;
  const target = values.target ?? '';
  if (named && values.low === 'nil') throw new Error('Low must be a number when Target is set.');
  return {low, target, batch: values.batch, fluid: values.fluidName ? decodeLuaString(values.fluidName) : ''};
}
function importText(text) {
  // Deliberately parse a small, documented Lua subset; never evaluate pasted code.
  const entries = [];
  let block = 'items', pending = '', pendingLine = 0, pendingDisabled = false;
  const lines = String(text).split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].trim();
    if (!line) continue;
    const disabled = line.startsWith('--');
    if (disabled) line = line.slice(2).trim();
    if (disabled && !pending && !line.startsWith('[')) continue;
    // Remove trailing comments without treating -- inside a quoted label as a comment.
    let quote = false, escape = false;
    for (let j = 0; j < line.length; j++) {
      if (escape) { escape = false; continue; }
      if (quote && line[j] === '\\') { escape = true; continue; }
      if (line[j] === '"') quote = !quote;
      if (!quote && line.slice(j, j + 2) === '--') { line = line.slice(0, j).trim(); break; }
    }
    if (!line) continue;
    if (!pending) {
      const header = line.match(/^cfg(?:\["(items|fluids)"\]|\.(items|fluids))\s*=\s*\{\s*\}?\s*;?$/);
      if (header) { block = header[1] || header[2]; continue; }
      if (/^(?:local\s+cfg\s*=\s*\{\s*\}|return\s+cfg|\}[,;]?)\s*;?$/.test(line)) continue;
      if (!line.startsWith('[')) throw new Error(`Line ${i + 1}: unsupported config syntax; nothing imported.`);
      pendingLine = i + 1;
      pendingDisabled = disabled;
    }
    pending += ' ' + line;
    const m = pending.match(/^\s*\[("(?:[^"\\]|\\.)*")\]\s*=\s*\{([\s\S]*)\}\s*[,;]?\s*$/);
    if (!m) continue;
    try {
      const f = parseFields(m[2]);
      const entry = makeEntry(decodeLuaString(m[1]), f.low, f.batch, f.fluid, f.target, block, true);
      entry.enabled = !pendingDisabled;
      entries.push(entry);
    } catch (err) { throw new Error(`Line ${pendingLine}: ${err.message} Nothing imported.`); }
    pending = '';
  }
  if (pending) throw new Error(`Line ${pendingLine}: incomplete or unsupported entry; nothing imported.`);
  return cleanEntries(entries);
}
function splitParts(text, limit) {
  if (!Number.isSafeInteger(limit) || limit < 1) throw new Error('Invalid paste limit.');
  // Slice by Unicode code point, retaining every newline and even oversized single lines.
  const characters = Array.from(text), parts = [];
  for (let i = 0; i < characters.length; i += limit) parts.push(characters.slice(i, i + limit).join(''));
  return parts;
}
if (typeof module !== 'undefined') module.exports = {parseAmount, formatAmount, makeEntry,
  formatEntry, formatLines, formatSections, formatConfigFile, cleanEntry, cleanEntries, importText, splitParts};
