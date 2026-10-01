# Good Idea

A ReaScript that makes ideas for starting a track - a Motif (a 1-4 bar hook),
a Phrase (1-4 bars of melody, chords, or both in one clip) or a Measure (8, 12
or 16 bars of melody, chords, bass and drums in a form) - calculated from the
rules of music, and puts the one you like into the project as MIDI. ReaImGui
for the window. **The user is a musician, not a programmer - explain in those
terms.**

Built in the same shape as its sister repos (Midi Catalogue - closest -
Starting Blocks, Midi Suggester, Midi Variator, ScaleView for REAPER). When
in doubt, do what Midi Catalogue does.

## Shape of it

| | |
| --- | --- |
| `reascripts/Good Idea.lua` | The window and the wiring. ReaImGui lives only here. |
| `reascripts/gi_theory.lua` | Keys, scales, chords on a degree, **which chord follows which**, cadences, voicing. ScaleView's ROOTS and SCALES and Starting Blocks' chord table, unchanged. |
| `reascripts/gi_idea.lua` | The settings, the dice, metre, the plan, harmony, rhythm, melody, chords/bass/drums parts, the block. |
| `reascripts/gi_midi.lua` | The MIDI file writer (Midi Catalogue's, plus a channel per note). |
| `reascripts/gi_place.lua` | Everything that touches REAPER. |
| `tools/demo.lua` | Ideas printed as note names. **Read this before and after any musical change.** |
| `docs/decisions/` | Why things are the way they are, one file per decision. |
| `docs/sessions/` | What happened in a session, written at the end of it. |

**`gi_theory` and `gi_idea` never touch `reaper.` or `ImGui.`** They take
plain tables and return plain tables. `gi_place` touches REAPER but not
ImGui. If a music question needs `reaper.` (the time signature, the tempo),
pass the value in - `I.meter(num, den)` is how.

`gi_idea` is loaded with `dofile(...).init(T)`: it is handed the theory
rather than finding it, so tests and the window load the same files the same
way. `init` builds `I.SETTINGS`, which needs `T`.

## The one idea

**An idea is a number**
([0002](docs/decisions/0002-an-idea-is-a-number.md)). `I.make(st, meter, seed)`
is a pure function of the settings, the metre and the idea number (1 to
`I.MAX_SEED`, 99999). The dice are Midi Variator's Park-Miller generator
(`I.random`), and every part of an idea draws from **its own stream**
(`I.stream(seed, name)`: pick, plan, harmony, rhythm, melody, chords, bass,
drums, and in 1.1 borrow and push), so changing how the chords are played
leaves the tune alone, and turning the drums off leaves the bass alone. The
tests hold all of that.

**1.0's ideas are kept** ([0010](docs/decisions/0010-figures-push-and-swing.md)):
`I.SETTINGS` is also the order `resolve` draws in, so **new settings go at
the end of the list** (the window's layout is separate), and a new feature
**draws nothing from the dice when it is off**. With Figures Plain, Push
None, Borrowed Off and no swing, every 1.0 idea number gives exactly the 1.0
idea; `test_idea` holds thirty, hashed before 1.1. Keep that true.

The randomness is only ever a choice among musically meaningful options
([0003](docs/decisions/0003-calculated-from-the-maths-of-music.md)): which
chord the T-S-D table allows next, which Euclidean turn, which step toward the
contour. Never random pitches.

## Settings: one list

`I.SETTINGS` is the single source. Each entry has `id`, `label`, `step` (which
numbered step of the window it sits in), `values`, `default`, and optionally
`any` (it can be left on "Any"), `weights`, `anyValues`/`anyWeights` (what Any
rolls among, when not all of `values`), `name(v)` (a label for a value),
`hints` (a sentence per value, for the musician) and `when(st)` (whether it
shows). The window draws a row per setting from it (`settingRow`), the state
is clamped and saved from it, `resolve` rolls it, and `test_ui` checks that
every value of every setting has a button and can be chosen. **Add a setting
there and everything else picks it up** - then give it a meaning in the
engine, and a test that it does what its hint says.

**Any** ([0005](docs/decisions/0005-every-setting-can-be-left-to-chance.md)):
`I.resolve(st, seed)` takes **one draw per setting, whether it is on Any or
not**, so fixing one setting never changes what another rolls, and `I.keep`
(turning every Any on screen into what this idea rolled) gives exactly the
same idea back. Bars are a setting per kind (`motifBars`, `phraseBars`,
`measureBars`; `I.barsSetting(kind)`), so switching kind keeps each one's
length.

**Swing is not in `I.SETTINGS`**: it is a slider (`st.swing`, 0-100), not a
row of buttons, and it is never rolled. It is clamped, saved and passed in
like `seed`, and `make` reads it from `st`.

**No dead controls.** A setting whose `when` is false is not drawn, and must
not change the idea: with no chords part, the tune walks over plain triads
one a bar whatever the chord settings say (`make` overwrites them in `r`).
`test_idea` holds that hidden settings change nothing.

## How an idea is made (`gi_idea`)

Everything is in **sixteenth-note steps** and **scale positions** (an integer
counting scale notes up from the root in MIDI octave -1; a third above is +2
in any scale), and turned into quarter notes and MIDI pitches only in
`toBlockNotes` at the end. `I.meter(num, den)` gives `bar` and `beat` in
steps; 6/8, 9/8 and 12/8 have a dotted-quarter beat. `I.strength(meter,
step)`: 3 downbeat, 2.5 half bar, 2 beat, 1 eighth, 0 sixteenth. "On the beat"
everywhere means strength >= 2.

1. **resolve** - see above.
2. **plan** ([0004](docs/decisions/0004-ideas-are-built-from-units.md)) -
   the idea is cut into units from `I.PLANS` (Motif, Phrase, by bars) or
   `I.FORMS` (Measure, by form and bars). A unit is `letter:bars[:cadence]`:
   a letter's first appearance is new; `a` again repeats it, `a'` answers it,
   `a~` sequences it (`u.shift`: up a step, down a step, up a fifth), `f`
   fragments the basic idea, `c` is a cadential unit. Cadence `X` is the
   idea's ending, drawn from `ENDINGS`. A repeat with a different cadence
   becomes an answer (`parsePlan`). Units start and end on beats (`snap`).
3. **harmony** - `unitChords` gives each unit `rel` slots `{ s, e, degree }`:
   - a repeat, or an answer or sequence to the same ending, copies its
     source's slots (shifted for a sequence) - **a Loop's chords really
     repeat**;
   - an answer to a different ending copies its source's slots **by time**
     up to `I.cutFor` (half way, on a beat), then walks to its own ending -
     so the copied half of the tune fits exactly as before;
   - anything else walks `T.progression` from the chord after the last.
   `countFor` decides how many chords: the chord pace, doubled for a
   fragment (a continuation speeds the harmony up), at least two for an
   ending, and an extra one for the opening unit so an idea starts on the
   tonic - but only if they still fall evenly on beats and bars. The
   timeline merges the same chord twice running into one. Every slot
   carries its scale, `sl.key`. Then:
   - **borrow** ([0011](docs/decisions/0011-borrowed-chords-rarely-and-named.md)):
     `I.borrow` - about one idea in four (`I.BORROW_CHANCE`), with Borrowed
     on Rare, a seven-note scale and at least four chords - swaps one chord
     (not the first, not the last two) for the same degree from another
     seven-note scale on the same key note (`BORROW_FROM`), setting
     `sl.key` to that scale and `sl.borrowed` to its name, its numeral
     against the home key (bVI) and its source. Only major or minor chords
     with a note outside the key.
   - **push** ([0010](docs/decisions/0010-figures-push-and-swing.md)):
     `I.push` moves a chord change on a beat back an eighth (`sl.s - 2`,
     `sl.pushed`), cutting the chord before. Quarter-note beats or longer
     only.
   Borrowing and pushing touch one occurrence of the harmony, so even an
   exact repeat's tune is `fit` to the chords under it, ending included.
4. **rhythm** - `I.cell`: Straight takes the k strongest grid steps;
   Syncopated takes a Euclidean spread (`I.euclid`) turned off the beat,
   over the whole bar (a syncopation needs room: 3 in 8, not 3 in 4 twice).
   `I.unitRhythm` reuses the first bar's cell often, and a closing unit holds
   its last note from half way through the last bar - or from where the last
   chord arrives, if later, so the tune comes home with the harmony.
   **Figures** (`I.figure`, laid over a cell a beat or two beats at a time,
   only where the beat is a quarter): two eighths become dotted (0, 3), two
   quarters dotted (0, 6), a beat an eighth-note triplet (0, 4/3, 8/3), two
   beats a quarter-note triplet (0, 8/3, 16/3). **Triplet steps are
   fractions**; `I.offGrid(step)` tells. The strength of a fractional step is
   0, so triplet notes are passing notes.
5. **melody** - `walkUnit`/`choose`: a weighted walk over the notes a sixth
   either side - steps likeliest, a Gaussian pull to the contour (`CONTOURS`;
   the Arch peaks at the golden section), chord tones only on the beat, a
   step or third back after a leap of a fourth or more, non-chord tones left
   by step, no tritone leaps, no augmented seconds, no note three times, and
   a step back to the note before last discouraged (no trills). Closing units
   end on `goalFor` (tonic for PAC, tonic third/fifth for IAC, a note of the
   chord under it for HC and open), with the note before pulled a step away.
   Repeats copy, sequences shift (`bestShift` picks the octave that stays in
   range and nearest), answers copy half and walk the rest, fragments copy
   the basic idea's first half, falling a step each time (each fragment a
   statement of its own: `fresh`). `fit` moves a copied note on the beat onto
   the chord now under it. Then, in this order: `I.wholeTriplets` drops any
   note between the sixteenths that is not part of a whole triplet (a copy
   or a closing note can cut one); **`I.untangle`**, the guarantee, removes
   three-in-a-row, tritone leaps and leaps over an octave inside a statement;
   then a note on a pushed chord's beat moves onto the push with it (not if
   it starts a triplet). **Every position becomes a pitch through the scale
   sounding at its step, `I.keyAt(ctx, step)`, never `ctx.key`** - under a
   borrowed chord that is the borrowed scale. `ctx.key` is only for the
   range and the tonic.
   `I.melodyRange` centres the tune on the fifth above the tonic nearest the
   register, **counted from the tonic**, so the same idea in another key is
   the same tune moved (tested).
6. **parts** - `chordsPart` (voiced by `T.voice`: close position, nearest the
   chord before; Block / Pulse / Broken with an arpeggio pattern; under a
   Phrase, the root in the bass), `bassPart` (Held / Pulse - on the kick
   drum's pattern, `I.kickPattern` - / Moving - root, fifth or octave, and a
   scale step into the next chord, from the scale sounding now), `drumsPart`
   (General MIDI, `I.DRUM`; kick pattern, backbeat or half-time snare when
   Calm, hats by pace - shuffled on triplets - open hat on syncopated
   grooves, a crash at the top and at each new section, a fill before each
   new section and at the end, the kick moved onto each push). A pushed
   chord is played from its beat (`gridStart`) with its first stroke moved
   onto the push (`onPush`), so it is not struck again on the beat. Pulse
   chords take figures; Broken chords roll in triplets.
7. **block** - `{ name, beats, notes, parts = { { name, notes, chan, drums } },
   layout = "one" | "tracks" }`. Channels
   ([0007](docs/decisions/0007-a-measure-on-tracks-a-motif-in-one-item.md)):
   in one item each part its own (melody 1, chords 2, bass 3); on tracks
   every part on 1; **drums always on 10** (`chan = 9`). **Swing** is
   applied here, last (`I.swingWarp`): each quarter note's grid stretched so
   its off-beat eighth lands up to 2/3 of the way through; whole-step starts
   and ends only (triplets are left alone); `I.swings(meter)` is false for
   6/8, 12/8 and 7/8. `idea.borrowed` lists borrowed chords with `text` for
   the window; the chord line marks a pushed chord `^` and a borrowed `*`.

The weights in `IV_WEIGHT`, `PULL`, `MOVES` and the rhythm tables were set by
reading `tools/demo.lua` output. If you change one, read the demo for every
kind before and after, then run the deep sweep (below).

## Harmony (`gi_theory`) ([0006](docs/decisions/0006-chords-stay-in-the-key.md))

- `T.chord(key, degree, colour)`: in a seven-note scale every other note;
  in any other scale **by ear** - a third if the scale has one, else a sus
  chord, then a fifth (a sharp fifth only over a major third). Mixed adds a
  seventh on chords a step, a fifth or a seventh above the tonic and a
  whole-tone ninth on the other major and minor chords. Always in key.
- `T.moveWeight`: seven-note scales read `MOVES`, indexed by the semitones
  from the tonic to each chord's root, so one table serves every mode;
  others use root motion. Diminished and augmented chords are drawn a
  quarter as often.
- `T.cadenceChords(key, half)`: V with a leading tone strongest; VII, v and
  the Phrygian bII where there is none; IV (plagal) for full closes only.
- Chords are in key, but for the rare borrowed one (`I.borrow`, above),
  which lives in `gi_idea` because it is a decision about one idea, not
  about harmony in general.
- `T.progression(key, n, { start, cadence, loopTo }, rnd)`: drawn forward,
  the join into the fixed ending accepted in proportion to its weight;
  after 80 failed draws, `T.likeliest` (Viterbi) finds the likeliest path,
  trying the other cadence chords, then an open ending that need not lead
  back, then any start. `test_theory` runs 7,680 of them.

## ReaImGui

Same rules as the sister repos: load it with `ImGui_GetBuiltinPath` and
`dofile(...)("0.9")`; every `PushID` has its `PopID` and every
`PushStyleColor` its `PopStyleColor`; the theme is pushed before `Begin` and
popped after `End`, outside the `visible` test. `flow()` lays a row of
buttons out wrapping at the window's edge. Every row's buttons sit inside
`PushID(setting id)`, which `test_ui` reads to tell one row's "Any" from
another's.

The steps are numbered as they are shown (a Motif has no Chords step, only a
Measure has an Arrangement). Swing is a `SliderInt` in the Feel step; in a
metre that cannot swing the window says why instead of showing it. A
borrowed chord is flagged in the body text (not dim, not the accent, not
the warning red) under the chord line. The idea is remade only when something changes
(`ui.dirty`), including the project's time signature at the edit cursor,
which `frame` compares every frame.

History is a browser's: New Idea after going back drops the ideas ahead. It
is not saved; the idea number is.

## Colour

The house scheme, unchanged: see `docs/COLOUR.md` (kept by hand). Every grey
is blue-shifted, R < G < B. Every button takes the dark ink, chosen or not.
**One departure**
([0009](docs/decisions/0009-the-tune-in-the-accent.md)): the roll shows
several parts, so only the tune takes the accent; chords and bass take the
controls' grey, and the drums are ticks in `#6D7581` along the bottom.

## Settings that outlive the window

Saved as `key=value;` in one ExtState string (`GoodIdea`/`state`): every
setting by id, `seed`, `autoplay` and `swing`. Loaded values go through
`tonumber(v) or v`, so bars, root, scale and seed come back as numbers and
names as names; `I.clampState` then puts anything that does not exist back
to its default.

## REAPER, from a script

Every `reaper.` call here was checked on 2026-10-01 against the REAPER API
functions page (REAPER 7.79) the user uploaded: all signatures match.
`ImGui_GetBuiltinPath` is ReaImGui's, so it is not on that page. Good Idea
calls nothing Midi Catalogue did not already call. Re-check any new call
there before using it, and write its mock from the same page.

- `TimeMap_GetTimeSigAtTime` returns `num, denom, tempo` - no retval first.
- `MIDI_InsertNote(take, sel, muted, startppq, endppq, chan, pitch, vel,
  noSort)`: `chan` is 0-based (drums are 9); noSort true for each, one
  `MIDI_Sort`.
- `GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")` is 1-based, 0 when not
  found; `InsertTrackAtIndex` is 0-based. So inserting at the selected
  track's number puts the new tracks straight under it; `idx <= 0` falls
  back to the end.
- `StuffMIDIMessage` mode 0 is the virtual keyboard; the channel is in the
  status byte (`0x90 + chan`). A sounding note in the preview is keyed by
  channel and pitch.
- `set_action_options(1)`: running the action again ends the script.
- `tests/reaper_mock.lua` is Midi Catalogue's, written **from the documented
  signatures**. It raises on anything it does not have. Add to it from the
  API docs, never from what the code expects.

## Tests

```
tools/test.sh
GOOD_IDEA_SWEEP=40 tools/test.sh      # the idea sweep forty times deeper
```

| | |
| --- | --- |
| `test_theory.lua` | Scales against ScaleView, positions, spelling, every chord of every scale in every colour in key and named, the walk's tendencies, cadences per scale, 7,680 progressions keeping their shape, voicing. |
| `test_idea.lua` | 735 ideas across six metres and every scale, every note and chord checked rule by rule against the scale sounding under it (about 570,000 checks); then by name: the same number is the same idea, 1.0's ideas unchanged, Keep, hidden settings, separate dice, a key change moves the same tune, Any rolls everything it offers, each setting does what its hint says, the four forms, bass and drums, figures (triplets whole), pushes, swing, borrowed chords (rare, placed, flagged, the tune bending). |
| `test_midi.lua` | The writer, read back by a parser that is not itself, format 0 and 1, channels. |
| `test_place.lua` | One item with channels, a track per part, export, audition on channel 10, against the mocked REAPER. |
| `test_ui.lua` | The real script against a mocked ReaImGui: every value of every setting has a button and can be chosen, every button in every kind clicked, steps shown and numbered, New Idea / back / forward / the number / Keep, insert, export, audition, Play new ideas, the swing slider (and its absence in 6/8 and 7/8), the borrowed-chord flag, the time signature, saved and nonsense settings. |

The sweep tallies each rule over every note it applies to and reports the
rule once, with a count and the first idea that broke it. **Run the deep
sweep after any musical change**: rare cases (one idea in thousands) only show
there. At 40x it is about 26,000 ideas and 21.7 million checks, and it found
four real bugs on the day it was written.

**Prove a test bites.** Every suite here was checked by deliberately breaking
what it covers - chord tones on the beat, the cadence's dominant, the drums'
channel, the channel byte, the dark ink, one draw per setting, separate dice
for chords and bass, the last tidy pass, gap-filling after a leap, the
tonic-anchored range, hidden settings, a Loop's repeated chords, a track per
part - and watching it fail. Separate dice were not covered at first:
nothing compared the bass or drums under two chord styles. A test does now,
and chords and bass drawing from one stream fails it.

A fresh container has no Lua: `apt-get install -y lua5.4` (or
`tools/run_lua.py` runs through lupa).

## Releasing

`index.xml` is the ReaPack index. Each `<version>` pins every file to a commit
hash, so a release is: commit the code, then add a new `<version>` block
pointing at that commit. Never edit an existing one. ReaPack keys a package by
its name, so do not rename `Good Idea.lua`.
