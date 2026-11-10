// The picture in the README: `node ableton/window.js` redraws ableton/window.png.
// A Measure: melody, chords and bass in a form.
require('./kit/test/picture.js')(__dirname, { bundle: 'GoodIdea.js', w: 860, h: 169,
  go(d) { const s = d.ctx.S.settings.find((x) => x.id === 'kind'); d.ctx.setSetting('kind', s.names.indexOf('Measure') + 1); } });
