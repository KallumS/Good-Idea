# 0014. Pull: the chords lie back an eighth; the tune, bass and drums stay on the beat

Taken 2026-10-01. Stands. Partners [0010](0010-figures-push-and-swing.md)'s push.
Widened by [0026](0026-flavours-ghosts-bass-pull-minor-schemata.md): in about
half the ideas (the engine decides) the bass lies back with the chords.

## Context

"I like the implementation of the push feature - could we also add one for
pull where the chords can arrive an eighth late?"

A push moves the whole band's arrival - the chord, the tune's note, the bass
and the kick - onto the "and" before the beat. The mirror of that, moving
everything late, would just be the beat moving. What players mean by a
late chord is the comping lying back while the rest stays on the beat.

## Decision

- **Pull** (None, Some, Lots, or Any) in the Feel step, shown only when the
  idea has a chords part.
- A pulled chord change arrives an eighth **after** its beat; the chord
  before is held through the beat to meet it, and nothing is struck between
  the beat and the pull.
- **Only the chords part moves.** Pull is applied to a copy of the timeline
  (`idea.chordTimeline`) that only the chords part plays from. The tune,
  the bass and the drums keep the harmony on the beat: the tune's note on
  the beat is already the new chord's, a moment before the chords catch up.
- A chord pushed is never also pulled. A pulled chord drops any stroke
  closer than a sixteenth behind it (a triplet arpeggio could otherwise put
  one there). The chord line marks it `_`.
- Pull has its own dice stream, so it changes nothing else, and with it on
  None (and the other 1.1 and 1.2 settings plain) 1.0's ideas are unchanged.

## Consequences

- Each chord now carries its beat (`sl.beat`), and the chords part lays its
  strokes out from that beat and then moves the first to where the chord
  really arrives (`onShift`) - one rule for push and pull alike.
- The sweep checks the chords part against its own timeline; named tests
  check the pull is exactly an eighth, nothing is struck early, the chord
  before is held, and the tune, bass and drums are note for note the same
  with and without it.

## Alternatives

**Pull everything late.** Rejected: indistinguishable from the beat moving.

**Pull the bass with the chords.** Rejected for now: the bass anchoring the
beat under a lazy chord is the sound asked for; a bass that lies back too is
a later choice.
