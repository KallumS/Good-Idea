# 0023. Three more chord styles, and named rhythms

Taken 2026-10-03. Stands. Widens [0015](0015-chord-rhythm-figures-and-one-and-a-half.md)
(more ways for the chords to play) and the Euclidean grooves of
[0003](0003-calculated-from-the-maths-of-music.md) (rhythms by name).
The reggaeton beat, left out here, came in 1.13 as a Drums Beat
([0025](0025-the-engine-decides-more.md)).

## Context

The fifth part of "add everything they suggest adding" (`docs/READING.md`,
first section): the accompaniment and its rhythm.

- **A Pedal style** - the "orchestrated sustain pedal", held notes in the
  middle register binding a texture together (*The Idiomatic Orchestra*):
  one held chord under the tune for each chord.
- **Afterbeats and offbeats** - Schoenberg's afterbeats, the polka's
  oom-pah and the reggae skank, muted guitar on every "and" (Hutchinson,
  ch. 14, accompaniment textures).
- **Chords that fill the tune's gaps** - busier where the tune holds and
  quieter where it moves, the chords' strokes placed in its gaps: call and
  response at the beat (Belkin, on foreground and background).
- **Named rhythms** - the son clave (3-2), its first bar the tresillo
  (3+3+2), the habanera, and 3+3+3+3+2+2 in sixteenths ("Shape of You",
  "All of Me") (Hutchinson, ch. 14), suggested for the pulsing chords and
  the pulsing bass. Each fits a bar of 4/4 in sixteenths (the clave, two
  bars of eighths, written in one bar of sixteenths).

The books agree on these, so nothing needed asking.

## Decision

**Style** gains three values, outside Any (which still rolls Block, Pulse
and Broken, so every idea number keeps its style):

- **Pedal** - each chord struck once, where it comes (on a push or a pull,
  too), and held to the next.
- **Offbeat** - short chords (a sixteenth long) on every eighth between the
  beats, from where the chord comes to where it goes: in 4/4 the "and" of
  each beat, in 6/8 the second and third eighths of each beat (oom-pah-pah).
- **Fill** - the chords answer the tune: struck on the eighths where the
  tune has held a note a beat or more, or rests, no closer than a beat
  apart, and held until the tune moves again; where the tune never stops
  under a chord, the chord is struck where it comes. Without a tune (a
  chords-only Phrase), Fill plays as Block.

**Groove** gains four values, outside Any (which still rolls Straight and
Syncopated): **Tresillo** (steps 0 6 12 of a 4/4 bar), **Habanera**
(0 6 8 12), **Clave** (0 3 6 10 12) and **3+3+3+3+2+2** (0 3 6 9 12 14).
In 4/4 the pulsing chords play the rhythm (and strike where a chord comes,
if it is not on one of its steps), the pulsing bass plays it, and the Drums
kind's kick plays it (no dotted or triplet figures on it: it is that
rhythm). The tune plays a named rhythm as Syncopated. In any other metre a
named rhythm is Syncopated.

## Consequences

- Version 1.11. Every 1.10 idea number is the same idea: the new values are
  only chosen.
- The sweep plays every sixth idea in one of the three new styles and every
  fifth in a named rhythm, and checks them: a pedal chord struck only where
  it comes, an offbeat chord off the beat and short, fill chords never on a
  note where the tune moves (but where a chord comes), a pulse and a pulsing
  bass on the rhythm's steps (or where a chord comes).

## Alternatives

**The named rhythms for the tune too.** Rejected: a tune that only ever
plays the clave's five notes is a drum part. The tune keeps its own
Euclidean syncopation, which the tresillo is one of.

**The reggaeton (dembow) beat** for the Drums kind (Hutchinson, ch. 14).
Not done: the Drums kind's beats are a separate setting; the dembow is a
kick-and-snare pattern, not a pulse, and can be added there the same way.
