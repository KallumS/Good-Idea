# 0007. A Measure goes on a track per part; a Motif or Phrase is one item

Taken 2026-10-01. Stands. Since [0013](0013-drums-are-a-kind-of-idea.md) a Measure always has
drums, and drums alone are a kind of idea, always one item (and since
[0016](0016-a-measure-has-no-drums-paces-in-numbers.md) a Measure has no
drums: melody, chords and bass, three tracks); since
[0012](0012-steps-fold-away.md) the Layout row sits with the output buttons.

## Context

"Phrase will generate ... a melody and chord pattern combined into one clip."
A Measure is melody, chords, bass and drums: four instruments. Drums played
by a piano are not drums, and a single item cannot hold four instruments'
sounds.

## Decision

- A **Motif** or **Phrase** is always **one item** on the selected track. In
  a Phrase with both, the tune is on MIDI channel 1 and the chords on 2, so
  REAPER can split them later by channel.
- A **Measure** has a **Layout** setting: **Tracks** (the default) inserts a
  new track per part - Melody, Chords, Bass, Drums - under the selected
  track, in one undo step, exactly as Midi Catalogue inserts a section; **One
  item** puts everything on the selected track, each part on its own channel
  (1, 2, 3).
- **Drums are always on channel 10** with General MIDI note numbers, in
  either layout, so any GM drum kit plays them.
- **Export .mid** follows the layout: a format 1 file with a track per part
  for Tracks, format 0 for one item. Each note keeps its channel.

## Consequences

- `gi_midi` and `gi_place` carry a channel per note (Midi Catalogue's wrote
  everything on channel 1). The audition plays each note on its channel and
  stops it on the same one.
- On tracks of their own, the melody, chords and bass are all on channel 1,
  which is what an instrument plugin on each track expects.

## Alternatives

**Always one item.** Rejected for a Measure: the drums would need splitting
out every time before they sounded like drums.

**Always tracks.** Rejected for a Phrase: the request asked for one clip.
