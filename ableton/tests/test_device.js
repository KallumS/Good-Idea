/* The Max for Live device, run in Node on a pretend Max and a pretend Live.
 *   python3 ableton/kit/build.py ableton/device.json && node --test ableton/tests/ */
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const path = require('node:path');
const suite = require('../kit/test/generator_suite.js');
require('../kit/test/palette_suite.js')();

const { device } = suite({ bundle: path.join(__dirname, '..', 'GoodIdea.js'), name: 'Good Idea' });

test('the same idea number with the same settings is the same idea', () => {
  const a = device(), b = device();
  assert.strictEqual(JSON.stringify(a.ctx.S.results), JSON.stringify(b.ctx.S.results));
});

test('each kind of idea inserts, a measure on one track per part', () => {
  for (const kind of ['Motif', 'Phrase', 'Measure', 'Drums']) {
    const d = device();
    const s = d.ctx.S.settings.find((x) => x.id === 'kind');
    d.ctx.setSetting('kind', s.names.indexOf(kind) + 1);
    const r = d.ctx.S.results[0];
    assert.ok(r, kind + ': ' + d.ctx.S.status);
    d.click('Insert');
    assert.ok(!d.ctx.S.warn, kind + ': ' + d.ctx.S.status);
    assert.strictEqual(d.set.tracks.length, r.parts.length, kind);
    if (kind === 'Measure') assert.ok(r.parts.length >= 2, 'a measure has more than one part');
    d.set.tracks.forEach((t, i) => assert.ok(t.kids.clip_slots[0].kids.clip.notes.length > 0, kind + ' part ' + (i + 1)));
  }
});

test('the key is shown once', () => {
  const t = device().texts();
  assert.strictEqual(t.filter((x) => x === 'Key').length, 1);
  assert.ok(t.includes('Good Idea — C Major'));
});
