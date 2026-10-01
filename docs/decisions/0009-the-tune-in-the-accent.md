# 0009. The tune takes the accent in the roll; the accompaniment takes grey

Taken 2026-10-01. Stands.

## Context

The house rule (Starting Blocks'
[0002](https://github.com/KallumS/Starting-Blocks/blob/main/docs/decisions/0002-notes-share-the-accent.md))
is that the notes in the preview roll share the accent with whatever is
switched on. Every sister repo previews one part at a time. Good Idea's roll
shows up to four at once - a tune, chords, a bass line and drums - and in one
yellow the tune disappears into the chords, and the drums (pitches 36 to 50)
squash everything else into a sliver.

## Decision

- **The tune takes the accent** (`#FFF200`): it is the idea.
- **Chords and bass take the controls' grey** (`#A9AFBA`), already on the
  ramp.
- **The drums are a strip of ticks along the bottom** in `#6D7581` (the
  scrollbar hover grey), not drawn by pitch, so they show the groove without
  stretching the pitch range.

## Consequences

- No new colours: both greys were already in the scheme. `docs/COLOUR.md`
  records the new uses.
- A chords-only Phrase shows grey notes only, since there is no tune to
  accent.

## Alternatives

**Everything in the accent**, as the house rule says. Rejected for the
reasons above.

**A colour per part.** Rejected: it would bring hues into a scheme whose
point is one accent on a cool grey ramp.
