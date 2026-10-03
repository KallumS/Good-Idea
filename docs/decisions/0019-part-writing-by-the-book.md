# 0019. Part-writing by the book, and shaped velocity

Taken 2026-10-02. Stands. Changes [0008](0008-velocity-100-accents-above-it.md)
(Shaped is now the default; Flat and Accents stay). Extends
[0018](0018-flavours-voicings-and-inversions.md) (how an inverted chord is
voiced) and [0006](0006-chords-stay-in-the-key.md) (the V of a half close
with Mixed). Changed by [0025](0025-the-engine-decides-more.md): a
six-four keeps its doubled bass (Hutchinson 26.12), and Part-writing is no
longer shown - always by the book.

## Context

Reading every source in the Educational Materials zip (`docs/READING.md`)
turned up five places where Good Idea went against the books. The user
asked to "fix 1 to 5", assuming the books are right except where they
disagree with each other - and to be asked about those. Four questions were
asked, and answered:

- **Doubling in an inverted chord.** Hutchinson: never double the bass of a
  first-inversion chord (but for a diminished triad, which doubles it). Open
  Music Theory: double it over do, re, fa or sol. Rimsky-Korsakov: never on
  an inverted dominant or seventh chord. **Chosen: Hutchinson.**
- **A half close's V.** Open Music Theory says "almost invariably a triad"
  on one page and "V or V7" on another. **Chosen: a triad with Mixed;
  Sevenths, chosen for sevenths everywhere, keeps its V7.**
- **The bass's distance below the chords.** Rimsky-Korsakov: "rarely more
  than an octave"; Belkin: no hole in the middle; Hutchinson and
  *Orchestration Analysis* allow more. **Chosen: within an octave and a
  fifth**, and never crossing (which all agree on).
- **The chords against the tune.** All: the tune on top. *Orchestration
  Analysis*: the accompaniment's top "just touches" the tune; *The Idiomatic
  Orchestra* and Belkin: the same register. **Chosen: just under the tune,
  allowed to overlap a step or two.**

Agreed by every source, and done without asking: a chord's seventh falls a
step into the next chord; no parallel fifths or octaves between the tune and
the bass; dynamics in the notes, not one velocity for everything.

## Decision

**Part-writing: By the book / Free** (Chords step, last in the list; no Any,
so it is free to add). By the book is the default; Free is 1.6 note for
note. By the book:

1. **No doubled bass in an inverted chord** (`I.undouble`). In close
   position a chord of four notes or more leaves the bass note out; otherwise
   that note takes the root's place, or the fifth's, the nearest free - so a
   voicing keeps its number of notes and its span (a rootless voicing takes
   the fifth or the ninth). A diminished triad doubles its bass, as
   Hutchinson says; a two-note (pentatonic) chord keeps what it has.
2. **A half close with Mixed is a plain V** (`sl.halfTriad`), unless the
   chord is borrowed or flavoured.
3. **The chords just under the tune.** Each chord's top may reach two
   semitones over the lowest tune note sounding over it (on the beat - a
   pull does not move it), and sits within an octave below that (two octaves
   for a spread voicing), never below C3. Before, the chords sat under the
   whole tune's lowest note, often more than an octave below the tune.
4. **The bass under the chords** (`I.spaceBass`): only octaves move. Each
   chord's own bass note goes in the octave under the chords and no more than
   an octave and a fifth under them, nearest where the line was going; a
   walking bass's other notes keep their distance from the next chord's note,
   so it still steps into it. Where the two cannot both be had, the step wins
   over the gap, and crossing never happens. A Phrase's own bass note likewise.
5. **A seventh falls a step** (`I.seventhTarget`): the voicing is chosen to
   have the note a semitone or a tone below the last chord's seventh, if the
   new chord has one there and does not keep the seventh's note; the chords'
   window stretches to take it.
6. **No parallel fifths or octaves between tune and bass** (`I.noParallels`):
   against the bass each chord stands on, the tune's later note moves (to
   another chord tone on the beat, a step off it), keeping every rule
   `untangle` keeps; a full or imperfect close's last note and the idea's
   first never move (a half close's or an open ending's last note may move
   to another note of its chord). A
   walking bass's passing notes keep clear of the tune themselves, holding
   their note where every choice would be parallel. So a different bass
   still leaves the tune alone.

**Velocity: Shaped** (new, the default): by the strength of the beat - 104 on
the downbeat, 98 on the half bar, 94 on a beat, 86 on an eighth, 80 off it
(and on triplet notes) - six more for an accented note, the chords ten under,
a chord's inner notes four under its top, the bass four under.

## Consequences

- Version 1.7. With Part-writing Free and Velocity Flat (and the 1.1-1.5
  settings plain), every 1.0 idea number is still the 1.0 idea. The new
  setting draws from the dice once, last, like every setting; By the book
  draws nothing more, but for the walking bass's passing notes, whose weights
  change.
- With the defaults, a 1.6 idea number keeps its tune (but for a note moved
  out of a parallel), its chords and their rhythm; the chords sit higher,
  nearer the tune, an inverted chord loses its doubled bass, and the bass may
  move an octave.
- Measured over 200 Measures (Block, Mixed): doubled bass 191 of 191 → 0; a
  seventh falling a step 96%; the bass meeting or crossing the chords 14% of
  strokes → 0, more than a twelfth under them 1.5%; the chords' top within a
  fifth under the tune (or a step or two over) 20% → 95%; parallel fifths
  and octaves 9.4% of moves → 1.2% (the rest are a walking bass with no way
  round); half closes on a seventh with Mixed 90 → 0.
- Exceptions the sweep allows: the whole-tone and diminished scales, where
  every way out of a parallel can be another (as for tritone leaps); a
  two-note idea whose both notes are fixed.
- Separate dice still hold where they did, with one honest exception: by
  the book the bass's octave follows the chords' voicing, so a different
  voicing can move the bass an octave (its rhythm and notes stay).

## Alternatives

**Change the old ideas outright.** Rejected: the user values idea numbers
keeping their idea; Free keeps 1.6 to hand.

**The tune against every bass note.** Tried first: the tune then changed
with the bass setting, breaking separate dice. The bass each chord stands on
is what the books' outer-voice rule is about; the passing notes avoid the
tune instead.

**Moving the bass's notes, not its octave, to keep under the chords.**
Rejected: the bass's notes are the harmony (root, or the inversion's note).
