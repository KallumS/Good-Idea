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
drums, in 1.1 borrow and push, in 1.2 pull and kit, in 1.5 colour and invert, in 1.8 applied, in 1.9 schema, in 1.10 tension, in 1.12 sixnine, in 1.14 ghost, in 1.15 chroma and passing, in 1.16 commontone), so changing how the chords are played
leaves the tune and the bass alone, and a different bass the tune and the
chords. (A Measure's Pulse bass still takes its kick pattern from the
`drums` stream, where 1.0's drums drew it.) The tests hold all of that.

**1.0's ideas were kept until 1.13**
([0010](docs/decisions/0010-figures-push-and-swing.md),
[0025](docs/decisions/0025-the-engine-decides-more.md)): the user let old
idea numbers go (no one was using the script yet), and the thirty 1.0
fingerprints were retired. The discipline that made it possible still
stands, because it is what makes the same number with the same settings the
same idea, and one setting's change leave the others' choices alone:

- `I.SETTINGS` is the order `resolve` draws in: **new settings go at the end
  of the list** (the window's layout is separate), one draw each.
- A new feature **draws from a stream of its own**, and nothing when off.
- **A setting is never taken out of the list.** One no longer wanted is
  *retired* (`retired = true`, never shown, one value): the Measure's
  `drums` switch, since 1.2 ([0013](docs/decisions/0013-drums-are-a-kind-of-idea.md)).
- A setting the engine decides is **`hidden`** (1.13): never shown
  (`I.shows`), left alone by Keep, but rolled - Progression (Walk or Any
  named, half and half), Part-writing (By the book), Form (all ten evenly),
  Bass pull (1.14: On the beat or With the chords, half and half).
- Every Off / Rare setting also has **Common** (1.6): the same draws with
  a higher threshold, so Common only ever adds to what Rare does.
- **A value is never renamed**; its label is (`name(v)`): the chord pace
  reads "0.5, 1, 1.5, 2, 4 a bar" over the stored `Slow`, `One a bar`,
  `Two a bar`. Values added to an Any-rolled setting were kept outside Any
  (`anyValues`) while old ideas mattered; since 1.13 that is a choice, not
  a rule (the forms and the Reggaeton beat are rolled; the 1.11 styles and
  rhythms, Power and 1.5 / 4 a bar are still only chosen).

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
   a letter's first appearance is new; cadences are PAC, IAC, HC, open and
   (1.8) **DC**, the deceptive V-vi (`T.progression`; the tune lands on vi
   preferring do); (1.13) **EC**, evaded: Extended's stretch half the time
   (`M.plan`), the cadence chord then I6 (`sl.evaded`, a spec with the third
   in the bass), the tune leaping up to a note of it that is not do; the 1.8 forms (Hybrid 1-4, Ternary, Extended - 0020) are
   outside Any; `a` again repeats it, `a'` answers it,
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
   - anything else walks `T.progression` from the chord after the last -
     or, with a named **Progression** (1.9,
     [0021](docs/decisions/0021-named-progressions.md)), takes the next
     chords of `I.PROGRESSIONS` in order (`schemaDegrees`, `sch.at` going
     round), its cadence's chords still last. `I.schemaFor` picks it (Any
     named among those that suit the mode; nil, with a reason for the
     summary, where it does not suit). Each chord is `{ degree, from =
     scale, bass = scale degree }`: `from` sets `sl.key`, `bass` sets
     `sl.bassPc`/`sl.inversion` in `harmony`, and the slot keeps `sl.spec`
     - **invert, borrow and applied skip a spec'd slot**, a flavour must
     keep its bass, and the merge keeps the Meyer's V4/3 V6/5 apart. A
     repeat (no shift) carries the list on, its tune `fit`, until `sch.at`
     is back where its source began (`u.schemaAt`), then copies. (1.14) A
     repeat that carries the list on to a point an earlier unit of the same
     length and close began at plays that unit's chords (a `twin`), so a
     Loop comes round the same, flavours and all. Each progression has a
     `major` and, where it can, a `minor` list (1.14: the galant ones too -
     the Fonte in minor goes iv to III, since ii is diminished). (1.16) A
     chord may name the degree the tune sings on its stage (`sing`, or two
     for a chord holding two stages: `stageAt`); the walk (`singNote`) and
     `fit` put the stage's first note on it, but for a close's last two
     notes - the Meyer, Prinner, Do-Re-Mi, Aprile (do ti re do over the
     Meyer's chords) and Pastorella (mi re fa mi over I V7 I) sing; the
     Ponte (I then V held) does not. The
     Blues goes a chord a bar by absolute bar (`sch.blues`). 1.13 added the
     Do-Re-Mi, Romanesca, Fonte and Monte; a spec may be `appliedTo` a degree
     (its V, `I.appliedKey`, `sl.applied.named`), plain again if a close cuts
     in before its target; a spec's bass is read in its own scale.
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
   - **applied** ([0020](docs/decisions/0020-applied-chords-cadences-and-forms.md)):
     `I.applied`, after borrowing - the chord before a major or minor chord
     (not the tonic) becomes its V/V7 or (one in four, `I.APPLIED_LEADING`)
     viio/viio7, made by `I.appliedKey` from the home scale with notes bent
     a semitone (`sl.key` is that scale, so the tune bends with it);
     `I.APPLIED_CHANCE` per chord; never first, last, cadence, borrowed, two
     running, or with no bent note; only where the chord after is the same
     every time round (copies follow their original). `sl.applied`; `>` in
     the chord line; `idea.applied` for the window.
   - **chromatic** (1.15, [0027](docs/decisions/0027-chromatic-chords.md)):
     `I.chromatic`, after applied, with Borrowed (`chroma` stream, two
     draws per close, taken or not) - the slot before a close's major V (a
     ii or IV, or the second half of a tonic, split) becomes the Neapolitan
     (Phrygian's II over fa, `sl.chromatic.kind = "N6"`) or an augmented
     sixth (`aug6Key`: the home scale with fa raised, la lowered, mi too for
     the German; `aug6Chord`, `ch.aug6`, named as the lead sheet's Ab7);
     the German - and (1.16) the Swiss, `Sw+6`, le do ri fi, in major keys
     only, sharing the German's weight there - splits the V for a cadential
     I6/4 (`spec.cadential`). Not a
     spec'd, borrowed, applied, moved chord or an applied chord's target;
     copies follow (`first[origin]`); with Triads N6 and It+6 only. By the
     book N6 is not `undouble`d, and `seventhTarget` wants fi's semitone up.
     `*` in the chord line; `idea.chromatic` for the window. The chord
     before keeps its root (`sl.rootHeld`, which `invert` skips).
   - **passing** (1.15): `I.passing`, with Applied (`passing` stream, one
     draw per pair) - where the bass climbs a tone into a root-position
     major or minor chord, a non-cadence chord of two beats or more gives
     its second half to the next chord's viio7 (`I.appliedKey(..., "vii")`;
     with Triads viio), `sl.applied.passing`, listed with the applied
     chords ("passing to"); both neighbours `rootHeld`.
   - **common tone** (1.16): `I.commonTone`, with Applied (`commontone`
     stream), not with Triads - a held major I or V of three beats or more,
     not a close's, becomes I - #ii°7 - I (#vi°7 for V) over its root
     (`commonToneKey`, `sl.commonTone`, inversion 3, `>` in the chord line,
     in `idea.applied`'s texts); the halves `rootHeld`.
   - **push** ([0010](docs/decisions/0010-figures-push-and-swing.md)):
     `I.push` moves a chord change on a beat back an eighth (`sl.s - 2`,
     `sl.pushed`), cutting the chord before. Quarter-note beats or longer
     only. Every slot keeps the beat it belongs to, `sl.beat`.
   - **pull** ([0014](docs/decisions/0014-pull-the-chords-lie-back.md)):
     `I.pull` makes a **copy** of the timeline (`idea.chordTimeline`) with
     some chord changes an eighth late (`sl.s + 2`, `sl.pulled`, the chord
     before held to meet it). **Only the chords part plays from the copy**;
     the tune and bass use the timeline on the beat - but with Bass pull
     With the chords (1.14, hidden, half the ideas), `I.pullBass` moves the
     bass's change at a pulled chord to where the chord comes, after
     `spaceBass`, holding the note before.
   - **flavour** ([0018](docs/decisions/0018-flavours-voicings-and-inversions.md)):
     `I.flavour`, with Flavours on Rare (any colour since 1.14; with Triads
     no `dim`, and `seventh` - whether the chord has one - rules out the
     rest that do not fit), after borrowing - about
     one chord in five that may (`I.FLAVOUR_CHANCE`; half on Common) becomes
     `T.flavourChord`: sus4, sus2, add2 (inside), add9 (on top), 9, 6 (half
     of them 6/9 since 1.12, on the `sixnine` stream; 6/9 is not in
     `T.FLAVOURS`, so older draws are unchanged), or the
     diminished seventh a third up. In key, offered only where the interval
     is real; keeps `sl.degree`; never the first, last or a cadence's chord
     (`cadenceSlots`), never a borrowed one, nor the truck driver's V, nor a
     chord whose copy is a cadence's (`blocked`: the copy could not follow
     it); `sl.flavour`.
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
   - **minor V** (1.13, 0025): `I.raiseDominant`, after the key change -
     every V in a key on the Minor scale is harmonic minor's (`sl.raised`;
     not a named chord, not the modes); `T.cadenceChords` weights it as V.
     Borrow and applied skip it.
   - **key change** (1.12, [0024](docs/decisions/0024-sixnine-power-and-key-change.md)):
     `I.keyChange` after harmony (which does not merge across `changeAt`):
     every slot from `I.changeAt` (the last unit starting at or after half
     way, on a bar, two bars or more to go) gets `T.transpose`d `sl.key`
     (fewest accidentals; `key.lift` = 12 where the key note passes B, read
     by `T.pitch` and `T.floorPos`), its chord rebuilt, `sl.moved`; the tune
     follows through `keyAt`. Truck driver: the new key's V (`sl.truck`,
     a `spec`) in the second half of the chord before. Borrow and applied
     skip moved slots. The truck driver only goes where the new tonic
     arrives: `I.changeAt` takes `tonicAt` (a look at the harmony first, the
     same dice giving the same chords) and picks the last section starting
     on the tonic; where none does (1.14), the latest that can is made to
     (`canTonic`: its first chord the tonic, if its close keeps the chords it
     needs; `harmony`'s `tonicAt`), and a named applied chord the truck's V
     cuts off is plain again. `idea.keyChange.text` for the window.
   Flavours and inversions follow a copied chord's original (`rs.orig` ->
   `sl.origin`): a repeat or a Loop comes round the same.
   Borrowing and pushing touch one occurrence of the harmony, so even an
   exact repeat's tune is `fit` to the chords under it, ending included.
   - **half close** ([0019](docs/decisions/0019-part-writing-by-the-book.md)):
     by the book, with Mixed, an HC unit's last chord is a plain triad
     (`sl.halfTriad`), unless borrowed or flavoured.
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
   a step back to the note before last discouraged (no trills), and two
   leaps the same way only where they outline a consonant triad
   (`I.outlinesTriad`, `I.leapsBad`; 1.13, Open Music Theory's cantus firmus
   rule - guaranteed by `untangle` after its octave fix, kept by the
   parallels pass and the appoggiatura). Closing units
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
   it starts a triplet); by the book, **`I.noParallels`** moves a note that
   makes parallel fifths or octaves with the bass each chord stands on
   (`ctx.bassPcAt`; never a full or imperfect close's last note, nor the idea's first);
   then **`I.tension`** (1.10,
   [0022](docs/decisions/0022-tension-and-a-second-voice.md); Tension
   Rare/Common, its own stream): a **suspension** (the note before a step
   down into a chord change held over it - `a.held` lifts the half-note
   cap - and the chord's note in late), an **appoggiatura** (a note a step
   above the chord's, leapt up to, on the beat - the one note on the beat
   off the chord, `nt.tension`), an **anticipation** (a close's last note
   an eighth early, off the beat). Each sets `nt.dissonance = { s, e, res }`
   but the anticipation; an exact repeat follows its source (`nt.from`,
   `decided`). By the book, `I.clearResolutions` takes the `res` note out
   of chords struck under a dissonance - not the root (`d.root`, the 9-8):
   Open Music Theory's rule. **`I.secondVoice`** (Second voice
   Thirds/Sixths, no dice) puts a note a third or a sixth under every note
   of the tune, on the chord on the beat; it is the last part (channel 4 in
   a Measure), and the chords sit under both. **Every position becomes a pitch through the scale
   sounding at its step, `I.keyAt(ctx, step)`, never `ctx.key`** - under a
   borrowed chord that is the borrowed scale. `ctx.key` is only for the
   range and the tonic.
   `I.melodyRange` centres the tune on the fifth above the tonic nearest the
   register, **counted from the tonic**, so the same idea in another key is
   the same tune moved (tested).
6. **parts** - `chordsPart` (voiced by `T.voiceAs` in the Voicing chosen -
   Close is `T.voice`, close position nearest the chord before, unchanged;
   Open, Drop 2, Drop 3, Drop 2 & 4, Shell, Rootless as 0018 says, Power
   (1.12: root, fifth, octave; outside Any), Drop 4 (1.14: the lowest of
   four close notes dropped; outside Any), reaching
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
   them too. **1.11** ([0023](docs/decisions/0023-chord-styles-and-named-rhythms.md)):
   Style Pedal (struck once at `sl.s`), Offbeat (a sixteenth on every
   eighth that is not a beat, from `sl.s`), Fill (`I.fillOnsets`: where the
   tune has held a beat or rests, a beat apart, each stroke held until the
   tune moves - `onsets.stops`; without a tune, Block); Groove Tresillo,
   Habanera, Clave, 3+3+3+3+2+2 (`I.RHYTHMS`, `I.rhythmOf` - 4/4 only,
   else `plainGroove` makes it Syncopated): the pulse plays its steps plus
   where a chord comes, `kickPattern` returns it (so the Pulse bass and the
   drums' kick play it, with no figures), the tune's `cell` treats it as
   Syncopated. All outside Any. Rate "1.5 a bar" is three chords to two bars, 3+3+2 beats;
   "4 a bar" is a chord on every beat (three a bar in 3/4).
   **By the book** (0019, `partWriting`, the default; Free is 1.6): each
   chord's window is just under the tune sounding over it on the beat (top
   at most two semitones over its lowest note), an inverted chord is
   `I.undouble`d (Hutchinson; a diminished triad excepted, and since 1.13 a
   six-four, which doubles its bass - Hutchinson 26.12), the voicing is
   chosen to take the note a seventh falls to (`I.seventhTarget`, the `want`
   of `T.voiceAs`), and `I.spaceBass` puts the Measure's bass in the octave
   under the chords, no more than a twelfth below, a walking bass still
   stepping in (only octaves move). A walking bass's passing notes avoid
   parallels with the tune (`bassPart`'s `tune`), so a different bass still
   leaves the tune alone.
7. **block** - `{ name, beats, notes, parts = { { name, notes, chan, drums } },
   layout = "one" | "tracks" }`. Channels
   ([0007](docs/decisions/0007-a-measure-on-tracks-a-motif-in-one-item.md)):
   in one item each part its own (melody 1, chords 2, bass 3); on tracks
   every part on 1; **drums** (the Drums kind) **always on 10** (`chan = 9`). **Swing** is
   applied here, last (`I.swingWarp`); so is **Shaped velocity**
   (`I.shapedVelocity`: by beat strength, chords ten under the tune, inner
   notes four under the top, bass four under): each quarter note's grid stretched so
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
   one item; `idea.drums` says the style, fills and change. 1.13: Reggaeton,
   the dembow (kick every beat, snare 3 6 11 14; 4/4 only); an answering
   bar's open hat falls back to the pickup on the ride or under quarter
   hats, and the pickup to the "a" of 4 where the snare has the "and".
   1.14: **ghost notes** (`I.ghostSteps`, the `ghost` stream, Off / Rare /
   Common): snare at `I.GHOST_VELOCITY` (`nt.ghost`, quiet at any Velocity)
   on the odd sixteenths (a shuffle's middle triplet), a place within a
   sixteenth of the snare likeliest (`GHOST_AWAY` elsewhere); never with the
   kick or snare (places compared in thirds of a sixteenth), never in a
   fill; the same every bar.

The weights in `IV_WEIGHT`, `PULL`, `MOVES` and the rhythm tables were set by
reading `tools/demo.lua` output. If you change one, read the demo for every
kind before and after, then run the deep sweep (below).

## Harmony (`gi_theory`) ([0006](docs/decisions/0006-chords-stay-in-the-key.md))

- `T.flavourChord(key, degree, flavour, seventh)` (0018): a flavour of the
  chord on a degree, from the scale, or nil where its interval is not real
  (no sus4 over a tritone). `T.voiceAs(ch, style, prev, lo, hi, floor, want)`:
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
- Chords are in key, but for the rare borrowed, applied and (1.15)
  chromatic ones (`I.borrow`, `I.applied`, `I.chromatic`, `I.passing`,
  above), which live in `gi_idea` because each is a decision about one idea,
  not about harmony in general.
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
| `test_theory.lua` | Scales against ScaleView, positions, spelling, every chord of every scale in every colour in key and named, the walk's tendencies, cadences per scale, 7,680 progressions keeping their shape, voicing; every flavour of every chord of every seven-note scale (in key, named, the interval it claims), every voicing of every C major chord by its definition (Drop 4 since 1.14), and the low interval limit. |
| `test_idea.lua` | 980 ideas of all four kinds across six metres and every scale, every note and chord checked rule by rule against the scale sounding under it, every drum idea against its fills (about 640,000 checks in all); then by name: the same number is the same idea, Keep, hidden settings, separate dice, a key change moves the same tune, Any rolls everything it offers (and never 1.5 or 4 a bar), each setting does what its hint says, the four forms, the bass (and no drums in a Measure), 4 a bar on every beat, figures (triplets whole; on every chord style and the walking bass; the tune's quarters and halves, and tune and chords figured together), pushes, pulls, swing, borrowed chords, the retired drums switch, drum ideas (styles, cymbals, the answering bar, fills, 1 to 16 bars), and flavours (all kinds, rare, never at a cadence, the same round a Loop), voicings in real ideas (and the bass under them), inversions (all three, each where it does its job - the six-fours as the textbooks allow them - diminished triads in first inversion, C/E), Common against Rare, part-writing by the book against Free (doubling, sevenths, the bass's spacing, the chords under the tune, parallels, half closes), shaped velocity, applied chords (rates, bent notes, D7 in C and the tune's F#, Loops, hidden) the 1.8 forms and deceptive close, named progressions (each as written, the blues bar by bar, the fallback and its reason, Any named suiting the key, a flavoured named chord keeping its bass), tension and the second voice (rates, all three kinds, Common keeping Rare's, a Loop leaning alike, the resolution left out by the book and kept under a 9-8, hidden, the tune untouched by a second voice, channels and tracks), the 1.11 chord styles and named rhythms (in chords, bass and kick, Syncopated elsewhere, never rolled), and 1.12's 6/9 (half the 6s, the same round a Loop), Power (root and fifth, never rolled) and key change (the same degrees moved up, the tune with them, from B to the C# above, the new key from the change even after Puff's I, the truck driver's V into the new tonic, hidden in a Phrase), and 1.13's hidden settings (not shown, half the ideas named, every form about one in ten, Keep leaving them), what outlines a triad, the minor V (and the tune's leading note; Aeolian's v kept), the evaded close (half Extended's stretches, on I6, the tune leaping up), the Do-Re-Mi, Romanesca, Fonte and Monte as written, the dembow (and a backbeat in 3/4), and the six-four's doubled bass; and 1.14's flavours with Triads and Sevenths (the ones each can take, a 7sus4 keeping its seventh), a named Loop's flavours the same each time round, ghost notes (none when Off, in most ideas on Rare, Common keeping Rare's, never in a fill, the same every bar, the rest of the drums unchanged), the bass with pulled chords (changing where they come, the note before held, on the beat the bass with no pull, the tune the same, half the ideas, not shown), the galant schemata in minor as written, the truck driver changing gear in nearly every Measure, and an applied chord it cuts off made plain; and 1.15's chromatic chords (all four kinds turn up, Common more than Rare, none with Borrowed off, three-note ones with Triads, the Neapolitan doubling its bass, fi rising to sol) and passing diminished chords (a seventh, or with Triads a triad, the window saying what it passes to, none with Applied off); and 1.16's common-tone diminished sevenths (Common more than Rare, named, none with Triads or Applied off), the Swiss sixth (in major only, the German still in major), the Aprile, Pastorella and Ponte as written in major and minor, and the schemata singing their tunes (70% of stages or more, the Aprile's re and the Meyer's fa over the same V6/5). The sweep checks each chromatic chord's notes and bass and that it goes to V (the German through the six-four), and a passing chord's bass climbing by semitones. The tests' `make` walks unless a test names a progression, and keeps the bass on the beat under pulled chords unless a test says. The sweep plays every idea in one of the seven voicings, every third on Common, every fifth with Free part-writing, every fourth Measure in a 1.8 form, every third idea with a named progression (the rest as the engine rolls it), Tension on Common with the other Commons (Off every seventh), a second voice every fourth, a 1.11 chord style every sixth and a named rhythm every fifth, a key change every seventh Measure (and Power and Drop 4 among the voicings), ghost notes in turn and the bass pull as the engine rolls it (1.14), and checks by the book on the rest; a ghost note is checked as a quiet snare on a weak place, alone. `GOOD_IDEA_SAY=1` prints passing checks too, with their numbers. |
| `test_midi.lua` | The writer, read back by a parser that is not itself, format 0 and 1, channels. |
| `test_place.lua` | One item with channels, a track per part, export, audition on channel 10, against the mocked REAPER. |
| `test_ui.lua` | The real script against a mocked ReaImGui: every value of every setting has a button and can be chosen, every button in every kind clicked with the steps folded and open, steps folding and their summary lines, the Drums kind, pull, 1.5 a bar, the chord paces in numbers and 4 a bar, flavours (with every colour since 1.14), the nine voicings, inversions, Progression, Part-writing and Form not shown (1.13), a Measure's three tracks, the layout by the buttons, steps shown and numbered, New Idea / back / forward / the number / Keep, insert, export, audition, Play new ideas, the swing slider (and its absence in 6/8 and 7/8), the borrowed-chord flag, the chromatic-chord line (1.15), the time signature, saved and nonsense settings. |

The sweep tallies each rule over every note it applies to and reports the
rule once, with a count and the first idea that broke it. **Run the deep
sweep after any musical change**: rare cases (one idea in thousands) only show
there. At 40x it is about 39,000 ideas and 24.8 million checks in 1.13 (28.6 million
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
chords side by side, Common borrowing only one; in 1.7 a doubled bass, a
seventh not wanted, the bass not spaced, the chords not under the tune,
parallels allowed, a half close keeping its seventh, chords as loud as the
tune, Free not being 1.6; in 1.8 an applied chord with no bent note,
two running, copies deciding afresh, the tune not bending, a deceptive
close going home, Any rolling the new forms, the tune ignoring do at a
deceptive close, a wrong leading-tone chord; in 1.10 tension when Off, an
appoggiatura not falling, a suspension unprepared or not held, an
anticipation on the beat, a minor ninth on the bass, a resolution onto the
bass, repeats leaning afresh, the chords doubling a resolution or dropping
a 9-8's root, a second voice off the chord, before the other parts, or
moving the tune; in 1.11 a pedal restruck, offbeat chords on the beat or
long, fill chords on a moving note, a named rhythm ignored or played in any
metre, Any rolling the new styles or rhythms, the tune playing the rhythm,
a figured kick, strokes past the next chord's beat (the Offbeat version of
that sabotage changed nothing; Fill's is caught); in 1.12 no 6/9, a 6/9
drawn afresh round a Loop, a 6/9 over a minor sixth, a power chord with a
third, Any rolling Power, a key change leaving the tune behind, merged
across the change, a minor truck-driver V, a key change in a Phrase, no
octave lift past B, a close aiming at the old tonic, borrowing after the
change; in 1.13 bad leaps not mended, a diminished triad counted as a
triad, the minor v left, no evaded close, an evaded close on I or landing
on do, a named applied chord ignored or kept when cut off, a named bass
read in the home key, a wrong dembow, a reggaeton in 3/4, the progression
not half and half, the forms not even, a six-four undoubled, an open hat
on the ride, the hidden rows shown; in 1.14 Drop 4 dropping the wrong
voice, flavours with Mixed only, a diminished seventh with Triads, the row
hidden with Triads, ghost notes loud, on any step, in fills, with the kick,
from the kit's dice, Common not keeping Rare's, the bass pull ignored,
holding nothing, on the beat too, shown, not half and half, a named Loop
drawn afresh, a flavour the cadence copy cannot follow, no minor Galant,
the minor Romanesca's raised ti falling, the minor Fonte to i, the truck
driver not made, its V flavoured, an applied chord kept at a gear change
(the first test missed it: a short chord's place, 3/4, was needed); "the
truck driver eats a close" was missed and is harmless - its own V makes
the close; in 1.15 the Neapolitan undoubled or in root position, fi not
rising (missed at first: the voicer alone gives 72%, the bar was 70%;
now 85%), a German sixth straight to V or at a half close, chromatic
chords before any cadence chord, with Borrowed off, four-note with Triads,
after their own degree, copies choosing afresh, an applied chord's target
made chromatic, a passing chord off the semitone, its neighbours inverted,
flavoured or moved by a third inversion, a seventh with Triads, with
Applied off, the second voice on the augmented sixth, no window line, Open
not spreading an Italian sixth; in 1.9 a progression
ignored, Any named ignoring the key, the blues wrong, inversions on named
chords, a silent fallback, the named bass ignored, a sus4 over a named bass
(missed by the quick sweep at first: a named test now covers it), a blues close
aiming for the tonic over IV or V (likewise) - and
watching it fail.
(`tools/bite.sh` says "BIT (crashed)" when the sabotage crashes the suite:
then make a cleaner sabotage, so a check, not the crash, does the catching.) Separate dice were not covered at first:
nothing compared the bass or drums under two chord styles. A test does now,
and chords and bass drawing from one stream fails it.

A fresh container has no Lua: `apt-get install -y lua5.4` (or
`tools/run_lua.py` runs through lupa).

## Releasing

`index.xml` is the ReaPack index. Each `<version>` pins every file to a commit
hash, so a release is: commit the code, then add a new `<version>` block
pointing at that commit. Never edit an existing one. ReaPack keys a package by
its name, so do not rename `Good Idea.lua`.

Every change the user asks for has been a release (1.0 to 1.16 so far), in
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

Hard-won, over 1.0 to 1.13. Read before changing anything.

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
Where the books disagree, ask (1.7 asked four questions: Hutchinson for
doubling, a triad on a half close with Mixed, the bass within an octave and
a fifth, the chords allowed to overlap the tune); where they agree, just do
it and cite them. **Quote a source only from its own text**: the extracted
texts of the Educational Materials are in the session scratchpad
(`edutext/`, made from the zip in `/root/.claude/uploads/`; remake them if
the scratchpad is gone). Twice a rule was credited to the wrong book (the
suspension's resolution is Open Music Theory's, not Hutchinson's), and
once Good Idea was found going against the very book chosen (Hutchinson's
26.12: a six-four doubles its bass) - read the source before writing the
rule, not after.

**Old ideas.** Until 1.13 every 1.0 idea number had to give the 1.0 idea;
the user let that go (0025). The habits stay - settings appended, a dice
stream per feature, nothing drawn when off, Common the same draw as Rare
with a higher threshold - because they keep one idea number stable within a
version and one setting's change from disturbing another's choices. To see
what a change does to existing ideas, compare with the previous release
through a worktree (`git worktree add <scratch>/old <commit>`) and say what
moved, measured: the 1.12 changelog claimed 1.9's ideas were unchanged, and
a check afterwards found 2 Measures in 100 with a tune note moved. A
published `<version>` is never edited, so check such claims before
publishing.

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
- A check that cannot fail is not a check: "Any never rolls Power" used the
  default voicing (Close, not Any); the Offbeat version of "strokes past
  the beat" changed nothing (Offbeat never strikes on the beat the pull
  holds over). And a sweep rule placed above where the audit defines the
  part it reads (`cp`) silently never ran - run new rules with
  `GOOD_IDEA_SAY=1` and see their counts.
- A sabotage that hangs or crashes is caught only in effect: make a cleaner
  one (a hang found `fit`'s unbounded search).
- **Never sabotage by hand in the working tree**: undoing it with `git
  checkout` threw away every uncommitted 1.14 change in that file (saved
  only by a stash made a moment before). `bite.sh` works on a copy.
- `bite.sh` copies the working tree as each bite starts: **do not edit
  the code while a batch runs**. A batch of a dozen takes 30-60 minutes;
  give the background job a long timeout (the default stops it at 30).

**Where bugs have hidden.** Repeats and copies: anything decided per chord
(flavours, inversions) must follow a copied chord's original (`sl.origin`),
or a Period's answer and a Loop drift. Tests comparing repeats must switch
off what is meant to be one occurrence only (borrowed chords). Fallbacks
that quietly degrade (a voicing that gives up to Close; Rootless playing
roots under a low tune) - test the style holds in real ideas. Chains: one
rule feeding another (a third inversion's resolution landing on a seventh).
Lua 5.4's `table.sort` is not stable: comparators must be total, and
fingerprints hash sorted strings.

**Passes that undo each other.** The tune is made, then tidied by passes
in order (`wholeTriplets`, `untangle`, the push, `noParallels`, `tension`);
a later pass can break an earlier one's guarantee. Every new tune rule must
be respected by every pass after the one that enforces it (1.13's leaps rule
was broken by `untangle`'s own octave fix, run after the check, then by the
anticipation), and no pass may move a close's goal (PAC, IAC, DC, EC).
Rare boxed-in cases (every way out a tritone, a parallel, three of a kind)
need a fallback, found only by the deep sweep.

**The deep sweep and the demo.** The sweep found real bugs in every
release - often two or three rounds of them (1.13 took four sweeps). Sweep
a **snapshot** of the tree (`cp -r reascripts tests tools <scratch>/snap`)
so work can go on meanwhile; reproduce a failure with a script that builds
the sweep's exact settings for that seed (the rotation is in `test_idea`'s
sweep loop); add any new setting's values to the rotation.
`tools/demo.lua Kind count first num den id=value` (count, then the first
idea number, then the metre; "id=Some value" quoted) prints ideas as note
names; the chord line shows ^ _ * > and C/E, and tension notes are marked
(s) (a) (ant).

**Releases that slip.** When a fix to version N lands in the commit after
N+1's work began, publish them together (1.12 carried 1.10 and 1.11) rather
than pin an index entry to a commit with a known bug.

**The container.** No Lua at first (`apt-get install -y lua5.4`). Textbook
sites (pressbooks, libretexts, pugetsound) are blocked by the network
policy; web search still quotes them. Never `cat > file` without a heredoc
(it waits on input and hangs); foreground `sleep` is blocked - run long
jobs in the background and wait for the notification. Scratch scripts go
in the session's scratchpad, never the repo. The container can restart
mid-task: background jobs stop (restart them), the working tree and the
scratchpad survive; commit often - the stop hook asks for a clean, pushed
tree at the end of every turn.

**Left open** (none asked for yet): not run inside REAPER; the
common-tone diminished seventh on IV or as an incomplete neighbour (0028);
tunes for the Romanesca, Fonte and Monte; per-drum choices in drum ideas; a drum idea matched to a
Measure's kick-and-bass; with Mixed figures, a dotted tune can rub against
triplet chords on the same beat; which steps are open is not remembered
between sessions. From 1.7-1.16: the Form row is hidden (one line in
`drawArrangement` and `hidden` in its setting to bring back); the truck
driver steps up plainly in about 1 Measure in 13 (the last section is only
its close); Fill strokes come where the tune rests only about half the time
(the rest are chord changes under a moving tune); "no more than two leaps in a row" (the cantus firmus's
other rule) is not enforced; the leaps rule is not checked in the
whole-tone and diminished scales; a Rootless sus2 triad (no three notes
but its root) is played close; ghost notes only on the snare.
