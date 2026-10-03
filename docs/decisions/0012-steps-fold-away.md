# 0012. The steps fold away; the layout sits with the output buttons

Taken 2026-10-01. Stands.

## Context

"The UI is getting a bit long, could some of the sections open out or hidden
behind menus?" And: "Layout Tracks/ One Item should be at the bottom of the
GUI alongside Export.mid and Audition."

By 1.1 every step was open all the time: well over eighty buttons with the
Feel, Chords and Arrangement rows all showing. Midi Catalogue met the same
complaint ([its 0010](https://github.com/KallumS/Midi-Catalogue/blob/main/docs/decisions/0010-show-a-family-at-a-time.md))
with "small until asked".

## Decision

- **Every step but the first folds.** A folded step is one line: its number,
  a button with its name (`Feel  +`), and a dim line of what is chosen in it
  ("pace Any  /  groove Syncopated  /  figures Dotted ..."). Clicking the
  button opens the step's rows (`Feel  -`); clicking again folds it.
- **The first step, Idea, never folds**: the kind and the length are the
  choice made every time.
- **All steps start folded**, every time the window opens. Which are open is
  the view, not a setting, so it is not saved - as in Midi Catalogue.
- **Buttons, not drop-down menus**, as in every window in the house: once a
  step is open, every choice in it is in view and one click away.
- **Layout moves down** beside Insert, Export and Audition, on one row with
  Velocity: both are about how the idea goes out, not what it is.

## Consequences

- The first screen is about twenty buttons instead of over eighty; the
  roll and the New Idea button no longer scroll off.
- Changing a folded setting is two clicks. The folded line says what is
  chosen, so it rarely needs opening just to look.
- The window tests open the steps they need (`openStep`, `openAll`), and
  sweep every button both folded and open.

## Alternatives

**Drop-down menus** (ReaImGui combos). Rejected: they hide the choices, and
the house has kept to buttons throughout.

**Tabs** for the steps. Rejected: a step's choices would be out of sight
while another's are shown, and the folded summary lines give the overview
tabs would lose.
