# 0018. Flavours for Mixed, a choice of voicings, and inversions where the bass steps

Taken 2026-10-02. Stands. Widens [0006](0006-chords-stay-in-the-key.md)
(every new chord is still built from the scale). In 1.6 the six-four rules
were tightened against the textbooks, diminished triads favour first
inversion, and every Rare setting gained Common (see the end). Widened by
[0026](0026-flavours-ghosts-bass-pull-minor-schemata.md): flavours with
Triads and Sevenths too, and a Drop 4 voicing.

## Context

"For Colour we have Triads, Sevenths and Mixed. Could Mixed have a small
chance to add a suspended or diminished chord as well as 2nd, 9th and 6th
flavours? Could we add a few buttons that allow the user to specify the chord
voicing such as closed, open, drop 2/3/4, shell and rootless if possible?
Could 1st, 2nd and 3rd inversions be rarely added to generations at random?"

## Decision

**Three settings, at the end of the list** (so every idea number rolls what
it rolled before), in the Chords step:

**Flavours** (Off, Rare; shown with Mixed or Any, in seven-note scales).
With Mixed, about one chord in five that may takes another colour
(`T.flavourChord`). Each is stacked from the scale, and offered only where
its interval is the real one in this key:

- **sus4** (or 7sus4 on a seventh chord) - only over a perfect fourth: no
  Fsus4 in C major, where F to B is a tritone;
- **sus2** - over a whole tone;
- **add2** - the 2nd voiced inside, between the root and the third;
- **add9** - the 9th voiced on top (the notes of Mixed's own add9, laid out
  as a 9th);
- **9** - a seventh chord with its ninth on top: Dm9, G9;
- **6** - a major sixth: C6, Dm6, F6 (and in Dorian, Cm's major sixth);
- **dim** - the diminished seventh chord a third up, which is the chord's
  upper notes without its root: G7 becomes Bm7b5 (G9 without the G), and in
  harmonic minor the full diminished seventh. Offered only where that chord
  is diminished.

A flavoured chord keeps the degree it stands for, so the walk, the cadences
and the tune read it as that chord; the tune's notes on the beat land on its
own notes. Never the first chord, the last, or a cadence's (each closing
unit's last chord, and the chord leading to a full or imperfect close).
Never a borrowed chord. A chord copied from another - a repeat, an answer's
first half, a Loop going round - takes its original's flavour, so the music
that comes round sounds the same.

**Voicing** (Close, Open, Drop 2, Drop 3, Drop 2 & 4, Shell, Rootless; Any
rolls them, Close three times as often). `T.voiceAs` makes every shape a
style allows in every octave and keeps the one nearest the chord before:

- **Close**: `T.voice`, exactly as before.
- **Open**: the root, the fifth, then the third an octave up and the rest
  above it (1 5 3 7 9).
- **Drop 2 / Drop 3 / Drop 2 & 4**: four voices in close position, with the
  second, the third, or the second and fourth from the top dropped an
  octave. A triad doubles its root (or its fifth, with the root inside); a
  five-note chord leaves out its fifth.
- **Shell**: the root, the third and the seventh (a sus chord's fourth or
  second for the third; a chord with no seventh takes its sixth, or fifth).
- **Rootless**: the third, fifth, seventh and the ninth in the root's place,
  with the third or seventh at the bottom (the A and B shapes). A chord whose
  ninth is not a whole tone keeps its root.

No two voices closer than a fourth below C3. A spread voicing may reach down
to G2 for its root, then up over the tune by a fifth, then an octave, before
it gives up and plays close position. Under a Phrase, the chords' own bass
note goes below the voicing (Close keeps its old placement, so 1.4's ideas
are unchanged).

The arranger's "drop 4" on its own is the bottom voice of a four-note close
chord dropped an octave - in root position just the root lower - so the
standard pairing, Drop 2 & 4, stands for it.

**Inversions** (Off, Rare). Where they do a job, as Open Music Theory's
"Harmonic syntax - prolongation" sets out - the bass moving by step:

- **first** (the third in the bass) where the bass steps into it or out of
  it: C G/B Am, F C/E Dm; likeliest when it does both (a passing chord);
- **second** (the fifth in the bass) only where a six-four belongs: over a
  held bass (I IV6/4 I), passing between steps (I V6/4 I6), or the tonic
  before the dominant at a cadence (the cadential I6/4 V);
- **third** (the seventh in the bass) only where it can fall a step onto the
  next chord's root or third, which takes that note in its bass (V4/2 I6).

About one chord in four that could be inverted is; never two running (but
for the chord a third inversion resolves to); never a flavoured chord, the
first, the last or a cadence's. Copies follow their original, where the bass
around them still allows it. The bass part, and a Phrase's own bass note,
play the inverted note; the chord line writes it over its bass: C/E.

## Consequences

- Version 1.5. With Flavours and Inversions Off and Voicing on Close, every
  1.0 idea number is still the 1.0 idea (the regression check turns them
  off, as it does Borrowed). They draw from streams of their own (`colour`,
  `invert`), and nothing when off.
- With the defaults (Flavours and Inversions on Rare), an idea from 1.4
  with Mixed may now have a flavoured chord, and its tune is fitted to it;
  an inversion changes only the bass.
- Measured over 400 C major ideas: flavours in about half of Measures (one
  chord in nine) and a sixth of Phrases (most of a Phrase's chords are its
  opening and its cadence); inversions in about two Measures in five and a
  fifth of Phrases.
- The sweep plays every idea in one of the seven voicings. Two of its rules
  are widened exactly as far as the new features need: a rootless voicing's
  ninth is allowed in the chords part, and the bass plays the inverted note.
- Tests check every flavour of every chord of every seven-note scale (in
  key, named, the interval it claims), every voicing of every chord of C
  major by its definition (a drop voicing, its dropped voices raised back,
  is close position with them second and fourth from the top), and in real
  ideas: flavours rare, all kinds, never at a cadence, the same each time a
  Loop goes round; voicings laid out as named and the bass under them;
  inversions rare, all three, each where it does its job, written C/E.
  Fifteen deliberate breakages were each caught.

## Alternatives

**Put the flavours straight into Mixed.** Rejected: every 1.0 idea that
rolled Mixed would have changed. A switch, on by default, keeps that.

**Out-of-key colour (a passing #iv dim7, an augmented chord).** Rejected
for now: [0006](0006-chords-stay-in-the-key.md) keeps chords in key; the
diminished chords here are the key's own.

**Inversions anywhere, by chance.** Rejected: a six-four or a seventh in the
bass in the wrong place sounds wrong, not adventurous. The dice choose only
among places an inversion does its job.

## 1.6: checked against the textbooks, and Common

"Could you check your knowledge on inversions using the internet please.
Also, anywhere we have an option called Rare could we add one for Common
too please?"

Searched: Open Music Theory ("6/4 chords as forms of prolongation"), Puget
Sound's *Music Theory for the 21st-Century Classroom* ("Types of six-four
chords"), Toby Rush's part-writing pages, and others quoting them. (The
pages themselves are blocked from the build container; the search results
quote them.) What held: first inversions as prolongations giving the bass a
line; V4/2 resolving to I6, the seventh falling by step. What was too
loose, and is now as the books say:

- **Cadential 6/4**: at a cadence - right before the cadence's own V, the
  chord a closing unit's dominant - and on a stronger beat than the V.
  (Before, any I before any V, on any beat.)
- **Passing 6/4**: the bass walks through three notes in one direction, on
  a weaker beat than the chord before, between two chords of the same
  function (I V6/4 I6, IV I6/4 IV6). (Before, steps either side, any
  direction, any beat, any functions.)
- **Pedal 6/4**: the bass held, on a weaker beat, between two chords of the
  same function (I IV6/4 I, V I6/4 V).
- **Diminished triads**: "usually found in first inversion (vii6)": in root
  position the fifth is a tritone over the bass, and the second inversion is
  rarely met. So a diminished triad is considered for inversion three times
  in four (`I.DIM_FIRST`) and only ever to first inversion. (A diminished
  seventh chord is left alone: the books note it is common in root
  position.)

"Weaker" and "stronger" are `I.weightAt`: the beat's strength, with the
first bar of each pair of bars stronger than the second, so ideas with a
chord a bar have strong and weak places too.

**Common**, beside Rare, in every setting that has Rare (no Any, so a new
value is free and no idea number changes):

- **Borrowed**: about two ideas in three borrow (`I.BORROW_CHANCE`), and
  one with eight chords or more borrows a second half the time
  (`I.BORROW_AGAIN`), never next to the first. Rare stays one chord.
- **Flavours**: half the chords that may (from one in five).
- **Inversions**: three in five of the chords that may (from one in four);
  never two running still holds, so Common gives about one and a half to
  twice as many.

The same draws decide Rare and Common (a higher threshold on the same
dice), so turning Rare to Common only ever adds.

Tests: the six-four check in the idea tests now holds the textbook rules
(cadence, beat, direction, function); a diminished triad is inverted far
more often than the rest and never to a 6/4; Common gives at least half as
much again as Rare for all three; two borrowed chords are never side by
side. Eight deliberate breakages, each caught.
