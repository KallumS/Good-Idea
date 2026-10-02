# Good Idea

A ReaScript that makes ideas for starting a track - a Motif (a 1-4 bar hook),
a Phrase (1-4 bars of melody, chords, or both in one clip), a Measure (8, 12
or 16 bars of melody, chords and bass in a form) or Drums (1-16 bars
of General MIDI drums with fills) - calculated from the rules of music, and puts the one you like into the project as MIDI. ReaImGui
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
| `reascripts/gi_idea.lua` | The settings, the dice, metre, the plan, harmony, rhythm, melody, chords/bass parts, drum ideas, the block. |
| `reascripts/gi_midi.lua` | The MIDI file writer (Midi Catalogue's, plus a channel per note). |
| `reascripts/gi_place.lua` | Everything that touches REAPER. |
| `tools/demo.lua` | Ideas printed as note names. **Read this before and after any musical change.** |
| `tools/bite.sh` | Breaks the code on purpose in a copy and runs a suite: proves a test bites. |
| `docs/HANDOVER.md` | The prompt to start a fresh session with. |
| `docs/READING.md` | Notes on every source in the Educational Materials zip: what each says, where Good Idea agrees, its gaps and ideas. **Read its first section before a musical change.** |
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
drums, in 1.1 borrow and push, in 1.2 pull and kit, in 1.5 colour and invert), so changing how the chords are played
leaves the tune and the bass alone, and a different bass the tune and the
chords. (A Measure's Pulse bass still takes its kick pattern from the
`drums` stream, where 1.0's drums drew it.) The tests hold all of that.

**1.0's ideas are kept** ([0010](docs/decisions/0010-figures-push-and-swing.md)):
`I.SETTINGS` is also the order `resolve` draws in, so **new settings go at
the end of the list** (the window's layout is separate), and a new feature
**draws nothing from the dice when it is off** (or draws from a stream of
its own). With Figures Plain, Push None, Pull None, Borrowed Off, Flavours
Off, Inversions Off, Voicing Close and no swing, every 1.0 idea number gives
exactly the 1.0 idea; `test_idea` holds
thirty, hashed by the 1.0 code in sorted order - a Measure without the 1.0
drums, since 1.3 has none
([0016](docs/decisions/0016-a-measure-has-no-drums-paces-in-numbers.md)).
Keep that true. So:

- **A setting is never taken out of the list.** One no longer wanted is
  *retired* (`retired = true`, never shown, one value): the Measure's
  `drums` switch, since 1.2 ([0013](docs/decisions/0013-drums-are-a-kind-of-idea.md));
  its one value is Off since 1.3, when a Measure lost its drums.
- Every Off / Rare setting also has **Common** (1.6): the same draws with
  a higher threshold, so Common only ever adds to what Rare does.
- **A value added to a setting Any rolls** goes outside Any
  (`anyValues`/`anyWeights` keep 1.0's list): "1.5 a bar" and "4 a bar" in
  the chord pace ([0015](docs/decisions/0015-chord-rhythm-figures-and-one-and-a-half.md),
  [0016](docs/decisions/0016-a-measure-has-no-drums-paces-in-numbers.md)).
- **A value is never renamed**; its label is (`name(v)`): the chord pace
  reads "0.5, 1, 1.5, 2, 4 a bar" over the stored `Slow`, `One a bar`,
  `Two a bar`.
  A value added to a setting with no Any (the kind's "Drums") is free.

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
not change the idea (for Drums: the key, the tune, the chords, push and
pull): with no chords part, the tune walks over plain triads
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
   `countFor` decides how many chords: the chord pace (`RATE`, 0.5 to 4 a
   bar, never more than one a beat), doubled for a fragment up to two a bar
   (a continuation speeds the harmony up; never slower than the pace), at least two for an
   ending, and an extra one for the opening unit so an idea starts on the
   tonic - but only if they still fall evenly on beats and bars. The
   timeline merges the same chord twice running into one. Every slot
   carries its scale, `sl.key`. Then:
   - **borrow** ([0011](docs/decisions/0011-borrowed-chords-rarely-and-named.md)):
     `I.borrow` - about one idea in four (`I.BORROW_CHANCE`), with Borrowed
     on Rare (two in three on Common, with a second chord, never adjacent,
     half the time in an idea of eight chords or more: `I.BORROW_AGAIN`), a seven-note scale and at least four chords - swaps one chord
     (not the first, not the last two) for the same degree from another
     seven-note scale on the same key note (`BORROW_FROM`), setting
     `sl.key` to that scale and `sl.borrowed` to its name, its numeral
     against the home key (bVI) and its source. Only major or minor chords
     with a note outside the key.
   - **push** ([0010](docs/decisions/0010-figures-push-and-swing.md)):
     `I.push` moves a chord change on a beat back an eighth (`sl.s - 2`,
     `sl.pushed`), cutting the chord before. Quarter-note beats or longer
     only. Every slot keeps the beat it belongs to, `sl.beat`.
   - **pull** ([0014](docs/decisions/0014-pull-the-chords-lie-back.md)):
     `I.pull` makes a **copy** of the timeline (`idea.chordTimeline`) with
     some chord changes an eighth late (`sl.s + 2`, `sl.pulled`, the chord
     before held to meet it). **Only the chords part plays from the copy**;
     the tune and bass use the timeline on the beat.
   - **flavour** ([0018](docs/decisions/0018-flavours-voicings-and-inversions.md)):
     `I.flavour`, with Mixed and Flavours on Rare, after borrowing - about
     one chord in five that may (`I.FLAVOUR_CHANCE`; half on Common) becomes
     `T.flavourChord`: sus4, sus2, add2 (inside), add9 (on top), 9, 6, or the
     diminished seventh a third up. In key, offered only where the interval
     is real; keeps `sl.degree`; never the first, last or a cadence's chord
     (`cadenceSlots`), never a borrowed one; `sl.flavour`.
   - **invert** (0018): `I.invert`, after the push - about one chord in four
     that could (`I.INVERT_CHANCE`; three in five on Common): first
     inversion where the bass steps in or out; second only as the textbooks
     allow a six-four - cadential (at a cadence, before its V, on a stronger
     beat: `I.weightAt`), passing (the bass one way through three notes) or
     pedal (held), those two on a weaker beat between chords of the same
     function; third only where the seventh falls a step onto the next
     chord's root or third (which takes it in its bass). A diminished triad
     is considered three times in four (`I.DIM_FIRST`), first inversion only
     (vii6). `sl.bassPc`, `sl.bassPos`,
     `sl.inversion`; `I.bassPcOf(sl)` is the bass everywhere. Not on
     flavoured or cadence chords; never two running.
   Flavours and inversions follow a copied chord's original (`rs.orig` ->
   `sl.origin`): a repeat or a Loop comes round the same.
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
   beats a quarter-note triplet (0, 8/3, 16/3). **In the tune** (`tune`,
   passed by `I.cell` only) a lone quarter becomes (0, 3) or a triplet and
   a lone half note (0, 6) or a quarter-note triplet, at `qdot`/`qtri`
   ([0017](docs/decisions/0017-the-tune-takes-figures-too.md)): an easy
   tune is mostly quarters and halves, which the other shapes never touch. **Triplet steps are
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
6. **parts** - `chordsPart` (voiced by `T.voiceAs` in the Voicing chosen -
   Close is `T.voice`, close position nearest the chord before, unchanged;
   Open, Drop 2, Drop 3, Drop 2 & 4, Shell, Rootless as 0018 says, reaching
   down to G2 and then over the tune before giving up to Close; Block /
   Pulse / Broken with an arpeggio pattern; under a Phrase, the bass note in
   the bass, under the voicing but for Close), `bassPart` (Held / Pulse - on the kick
   drum's pattern, `I.kickPattern` - / Moving - root, fifth or octave, and a
   scale step into the next chord, from the scale sounding now). A Measure
   is melody, chords and bass: **no drums** since 1.3
   ([0016](docs/decisions/0016-a-measure-has-no-drums-paces-in-numbers.md));
   drums are the Drums kind's alone. A chord's
   strokes are laid out from its beat (`gridStart`) to the next chord's
   beat, then the first moves to where the chord arrives (`onShift`): onto
   a push (not struck again on the beat), or back to a pull (nothing
   before it, nothing within a sixteenth after). **Figures reach every chord
   style** ([0015](docs/decisions/0015-chord-rhythm-figures-and-one-and-a-half.md)):
   Block takes stabs (`blockFigures`: a dotted quarter in, or a
   quarter-note triplet), Pulse and Broken take `I.figure` over their
   strokes (Broken rolls in triplets with Triplets), and a Moving bass takes
   them too. Rate "1.5 a bar" is three chords to two bars, 3+3+2 beats;
   "4 a bar" is a chord on every beat (three a bar in 3/4).
7. **block** - `{ name, beats, notes, parts = { { name, notes, chan, drums } },
   layout = "one" | "tracks" }`. Channels
   ([0007](docs/decisions/0007-a-measure-on-tracks-a-motif-in-one-item.md)):
   in one item each part its own (melody 1, chords 2, bass 3); on tracks
   every part on 1; **drums** (the Drums kind) **always on 10** (`chan = 9`). **Swing** is
   applied here, last (`I.swingWarp`): each quarter note's grid stretched so
   its off-beat eighth lands up to 2/3 of the way through; whole-step starts
   and ends only (triplets are left alone); `I.swings(meter)` is false for
   6/8, 12/8 and 7/8. `idea.borrowed` lists borrowed chords with `text` for
   the window; the chord line (`I.chordLine`) marks a pushed chord `^`, a
   pulled one `_`, a borrowed one `*`, and writes an inverted one over its
   bass, C/E.

8. **Drums, the kind** ([0013](docs/decisions/0013-drums-are-a-kind-of-idea.md)):
   `make` hands off to `I.makeDrums` before any harmony. `I.drumIdea` makes
   a bar of groove for the Beat (`drumGroove`: the kick from `kickPattern`
   or a breakbeat template, figures on it but for four on the floor; the
   backbeat, half-time snare on 3, or a clap; the time on hats or ride by
   pace, shuffled on triplets), plays bars in pairs with the second
   answering the first (pickup kick, kick before the snare, or open hat),
   puts fills where Fills says (`drumFill`: a beat, two when busy or at a
   phrase end when flowing - roll, toms, snare and toms, or triplets - a
   kick under the first note) and a crash on the downbeat each fill leads
   to, wrapping to the top. Notes are cut at the end. One part, channel 10,
   one item; `idea.drums` says the style, fills and change.

The weights in `IV_WEIGHT`, `PULL`, `MOVES` and the rhythm tables were set by
reading `tools/demo.lua` output. If you change one, read the demo for every
kind before and after, then run the deep sweep (below).

## Harmony (`gi_theory`) ([0006](docs/decisions/0006-chords-stay-in-the-key.md))

- `T.flavourChord(key, degree, flavour, seventh)` (0018): a flavour of the
  chord on a degree, from the scale, or nil where its interval is not real
  (no sus4 over a tritone). `T.voiceAs(ch, style, prev, lo, hi, floor)`:
  the voicings; `T.roleOf(ch, pc)` says what a note is (R 3 4 5 6 7 9);
  `ch.nine` is the whole-tone ninth a rootless voicing adds.
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

**The steps fold** ([0012](docs/decisions/0012-steps-fold-away.md)): every
step but Idea is a button (`fold`) - "Feel  +" folded, with a dim summary
line of its choices (`summaryOf`); "Feel  -" open, with its rows. The fold
button sits inside `PushID("open:" .. name)`. All start folded; which are
open (`ui.open`) is the view and is not saved. Velocity and Layout sit on
one row by the output buttons.

The steps are numbered as they are shown (a Motif has no Chords step, only a
Measure has an Arrangement, Drums have no Key but a Drums step). Swing is a
`SliderInt` in the Feel step; in a
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
controls' grey. A drum idea has nothing else, so its drums fill the roll
in lanes, in the accent.

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
| `test_theory.lua` | Scales against ScaleView, positions, spelling, every chord of every scale in every colour in key and named, the walk's tendencies, cadences per scale, 7,680 progressions keeping their shape, voicing; every flavour of every chord of every seven-note scale (in key, named, the interval it claims), every voicing of every C major chord by its definition, and the low interval limit. |
| `test_idea.lua` | 980 ideas of all four kinds across six metres and every scale, every note and chord checked rule by rule against the scale sounding under it, every drum idea against its fills (about 583,000 checks); then by name: the same number is the same idea, 1.0's ideas unchanged, Keep, hidden settings, separate dice, a key change moves the same tune, Any rolls everything it offers (and never 1.5 or 4 a bar), each setting does what its hint says, the four forms, the bass (and no drums in a Measure), 4 a bar on every beat, figures (triplets whole; on every chord style and the walking bass; the tune's quarters and halves, and tune and chords figured together), pushes, pulls, swing, borrowed chords, the retired drums switch, drum ideas (styles, cymbals, the answering bar, fills, 1 to 16 bars), and flavours (all kinds, rare, never at a cadence, the same round a Loop), voicings in real ideas (and the bass under them), inversions (all three, each where it does its job - the six-fours as the textbooks allow them - diminished triads in first inversion, C/E), and Common against Rare. The sweep plays every idea in one of the seven voicings, and every third on Common. |
| `test_midi.lua` | The writer, read back by a parser that is not itself, format 0 and 1, channels. |
| `test_place.lua` | One item with channels, a track per part, export, audition on channel 10, against the mocked REAPER. |
| `test_ui.lua` | The real script against a mocked ReaImGui: every value of every setting has a button and can be chosen, every button in every kind clicked with the steps folded and open, steps folding and their summary lines, the Drums kind, pull, 1.5 a bar, the chord paces in numbers and 4 a bar, flavours (shown only with Mixed), the seven voicings, inversions, a Measure's three tracks, the layout by the buttons, steps shown and numbered, New Idea / back / forward / the number / Keep, insert, export, audition, Play new ideas, the swing slider (and its absence in 6/8 and 7/8), the borrowed-chord flag, the time signature, saved and nonsense settings. |

The sweep tallies each rule over every note it applies to and reports the
rule once, with a count and the first idea that broke it. **Run the deep
sweep after any musical change**: rare cases (one idea in thousands) only show
there. At 40x it is about 39,000 ideas and 22.1 million checks (28.6 million
in 1.2, when a Measure had drums to check); it has found
real bugs in every release so far.

**Prove a test bites.** Every suite here was checked by deliberately breaking
what it covers - chord tones on the beat, the cadence's dominant, the drums'
channel, the channel byte, the dark ink, one draw per setting, separate dice
for chords and bass, the last tidy pass, gap-filling after a leap, the
tonic-anchored range, hidden settings, a Loop's repeated chords, a track per
part; in 1.2 pull keeping the tune still, nothing struck before a pull, the
held chord, 1.5 a bar kept out of Any, block stabs, the figured bass, fills
where asked, the crash after a fill, the answering bar, the drum channel,
the retired setting's place, folding, the layout row, the Drums step; in
1.3 drums back in a Measure (caught by the idea, window and placement
tests), Any rolling 4 a bar, 4 a bar slower than every beat, the kick
pattern drawn from another stream, the retired switch On, the labels, and
a held bass ignoring a push; in 1.4 the 1.3 engine, whose tune hardly took
figures; in 1.5 a sus4 over a tritone, drop 2 dropping the wrong voice, a
rootless voicing with its root, no low interval limit, Close played open,
flavours at a cadence, flavours drawn afresh each time round, flavours or
inversions when off, the bass ignoring an inversion, any six-four, a third
inversion onto a seventh, no slash in the chord line, a spread voicing over
a Phrase's bass, Flavours shown with Triads; in 1.6 a cadential 6/4 anywhere,
a passing 6/4 turning back, a pedal 6/4 on a strong beat, diminished triads
like any other, a diminished 6/4, Common no more than Rare, two borrowed
chords side by side, Common borrowing only one - and watching it fail. Separate dice were not covered at first:
nothing compared the bass or drums under two chord styles. A test does now,
and chords and bass drawing from one stream fails it.

A fresh container has no Lua: `apt-get install -y lua5.4` (or
`tools/run_lua.py` runs through lupa).

## Releasing

`index.xml` is the ReaPack index. Each `<version>` pins every file to a commit
hash, so a release is: commit the code, then add a new `<version>` block
pointing at that commit. Never edit an existing one. ReaPack keys a package by
its name, so do not rename `Good Idea.lua`.

Every change the user asks for has been a release (1.0 to 1.6 so far), in
this order:

1. Read the demo before; make the change; read the demo after.
2. `tools/test.sh`, then `GOOD_IDEA_SWEEP=40 tools/test.sh` (four or five
   minutes - run it in the background).
3. Write the tests for what the hints promise; break each new thing on
   purpose and watch a test fail (see below).
4. Bump `Version:` in the header of `Good Idea.lua`.
5. A decision record (or a dated section on the one it extends, with a
   status note on any it changes), CLAUDE.md, README, and the day's session
   log (append a `# Later - x.y: ...` section; never rewrite an old one).
6. Commit the code; add the `<version>` block pinned to that commit, with a
   changelog in the musician's words; commit; push.

## What has been learned

Hard-won, over 1.0 to 1.6. Read before changing anything.

**Working with the user.** A musician, not a programmer: every reply in
musical terms (what you will hear, which bars, which chords), with numbers
measured, not guessed. Ask nothing that a sensible default and a sentence
in the reply can settle - e.g. "0.5 a bar" already existed as Slow, so it
was relabelled and the user told; "drop 4" alone is not a standard voicing,
so Drop 2 & 4 stands for it and the user was told it can be added. Say
plainly what changed for old idea numbers. The user values checking against
sources: the Educational Materials zip (Hutchinson's textbook, 100 Open
Music Theory pages - its "Inversion" page is the twelve-tone kind;
"Harmonic syntax - prolongation" is the chords one - and nine orchestration
sources), all summarised in `docs/READING.md`, and, when asked, the web.

**Keeping old ideas.** Settings are appended, never removed (retire them);
new values of an Any-rolled setting stay outside Any; every new feature has
its own dice stream and draws nothing when off; Common uses the same draw as
Rare with a higher threshold, so it only adds. When a part is removed (the
Measure's drums, 1.3) the 1.0 fingerprints are remade by the 1.0 code
itself: `git worktree add <scratch>/old 872be29`, hash without that part.

**Measure, then tune.** Every rate here (figures, flavours, inversions,
borrowing) was set by a scratch script tallying many ideas - per idea and
per chord or beat - and compared with the release before through a
worktree of the old commit. A first guess was wrong more often than right:
the tune's figures were 15% of beats, not "fine"; Common inversions are
1.6x Rare, not 2.4x, because "never two running" caps them. Set test
thresholds between the clean code's number and the old code's, with room.

**Verify a claim before writing it.** "The chords are unchanged" was false:
their rhythm was, but chords are voiced under the tune's lowest note, so a
new tune moves them. Check the claim with a script, then write the narrower
true one.

**Proving a test bites** (`tools/bite.sh "what" test_x.lua "r(path, old,
new)"`: copies the repo, applies the replace, runs one suite, prints BIT /
MISSED / DID NOT APPLY):

- A sabotage must actually change behaviour. "Close played open" first
  edited a variable the Close path never reads, and "missed" - the test was
  fine, the sabotage was not.
- A MISSED can be a real gap: the low interval limit was never exercised
  because tests voiced chords only in the middle register.
- A test written for a sabotage must also be run on clean code: the low
  register test then found a real muddy fallback.
- "DID NOT APPLY" means the line changed since; re-read it.

**Where bugs have hidden.** Repeats and copies: anything decided per chord
(flavours, inversions) must follow a copied chord's original (`sl.origin`),
or a Period's answer and a Loop drift. Tests comparing repeats must switch
off what is meant to be one occurrence only (borrowed chords). Fallbacks
that quietly degrade (a voicing that gives up to Close; Rootless playing
roots under a low tune) - test the style holds in real ideas. Chains: one
rule feeding another (a third inversion's resolution landing on a seventh).
Lua 5.4's `table.sort` is not stable: comparators must be total, and
fingerprints hash sorted strings.

**The deep sweep and the demo.** The sweep found real bugs in every
release; it now varies voicing and Rare/Common, so add any new setting's
values to its rotation. `tools/demo.lua Kind count from num den id=value`
prints ideas as note names; the chord line shows ^ _ * and C/E.

**The container.** No Lua at first (`apt-get install -y lua5.4`). Textbook
sites (pressbooks, libretexts, pugetsound) are blocked by the network
policy; web search still quotes them. Never `cat > file` without a heredoc
(it waits on input and hangs); foreground `sleep` is blocked - run long
jobs in the background and wait for the notification. Scratch scripts go
in the session's scratchpad, never the repo.

**Left open** (none asked for yet): not run inside REAPER; a separate Drop
4; out-of-key colour (a passing #iv dim7) - 0006 keeps chords in key;
flavours for Triads or Sevenths; ghost notes and per-drum choices in drum
ideas; a drum idea matched to a Measure's kick-and-bass; pull for the bass;
with Mixed figures, a dotted tune can rub against triplet chords on the same
beat; which steps are open is not remembered between sessions.
