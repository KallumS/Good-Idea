# 0013. Drums are a kind of idea; a Measure always has drums

Taken 2026-10-01. Stands, but for the Measure's drums: since
[0016](0016-a-measure-has-no-drums-paces-in-numbers.md) a Measure has none.
Retires the Measure's Drums switch
([0007](0007-a-measure-on-tracks-a-motif-in-one-item.md)).

## Context

"Could we remove the drums toggle from the Measure section and add it
alongside Motif, Phrase and Measure. The new drum generator will make drum
patterns using general midi drum mapping. Drum generations to be 1 - 16 bars
with the ability to create drum fills."

## Decision

- **Drums is a fourth kind**, beside Motif, Phrase and Measure: 1 to 16 bars
  (or Any) of General MIDI drums on channel 10, in one item.
- **Its own step, Drums**: the **Beat** (Backbeat; Half-time; Four on the
  floor; Breakbeat - a backbeat outside 4/4, and the idea says so), **Fills**
  (None; At the end; Every 4 bars; Every 2 bars) and the **Cymbal** (Hats;
  Ride, with the bell on the one and the hat pedal on the backbeat). The
  Feel step's pace, groove, figures and swing apply; push and pull, the key,
  the tune and the chords do not, and are not shown.
- **How a drum idea is made** (`I.drumIdea`): a bar of groove from the same
  pieces as a Measure's drums - the kick's metric or Euclidean pattern, the
  backbeat - with figures on the kick (not on four on the floor). Bars come
  in pairs, the second answering the first with one change chosen for the
  idea: a pickup kick, a kick before the last snare, or an open hat. A fill
  takes the last beat of its bar (two when busy, or at the end of a phrase
  when flowing): a snare roll, a run down the toms, snare then toms, or
  triplets; a kick under its first note; a crash on the downbeat it leads to
  - the top of the idea for the last one, because a drum idea is made to
  loop. No fills, no crashes.
- **A Measure always has drums.** The switch is gone from the window. The
  setting stays in the settings list - never shown, only ever "On", an old
  saved "Off" coming back "On" - because the list is the order the dice are
  drawn in, and taking it out would have changed every idea after it.

## Consequences

- The Measure's own drums are unchanged (and 1.0's ideas with them); the
  Drums kind has its own generator and its own dice stream (`kit`), so
  nothing else moved.
- The roll draws a drum idea as lanes, one per drum, in the accent. In a
  Measure the drums are ticks in grey and the tune takes the accent
  ([0009](0009-the-tune-in-the-accent.md)); in a drum idea there is no tune,
  and the drums are the idea.
- The sweep checks every drum idea: General MIDI drums only, a kick on every
  downbeat, a snare or a fill in every bar, fills exactly where the setting
  puts them, toms only in fills, a crash where each fill lands.

## Alternatives

**Keep the switch and add the kind.** Rejected: the request was to move it,
and a Measure without drums is a Phrase with a bass line.

**Velocity-shaped grooves (ghost notes).** Not with the house rule of
velocity 100, accents at 115 ([0008](0008-velocity-100-accents-above-it.md)).
