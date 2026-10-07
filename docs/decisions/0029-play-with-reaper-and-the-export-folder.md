# 0029. Play with REAPER, a click on the roll plays from there, and Export's folder

Taken 2026-10-07. Stands. Extends [0001](0001-a-reascript-not-a-jsfx.md)
(the preview is still the virtual keyboard from a deferred script) and the
export of 1.0.

## Context

The user asked for three things:

- "a way to implement play sync with Reaper - for example, pressing play in
  Reaper starts playing Good Idea. Due to this, we would also need a mute
  or ignore play button."
- "a way to click somewhere on the midi generation and start playing from
  that point."
- "I've also tested the Export.mid button and it doesn't seem to work, I
  can't find the exported midi. Could there be a setting to change where
  the midi is saved and a button to open that folder?"

Export had written to a `Good Idea` folder in REAPER's resource path since
1.0 (`~/Library/Application Support/REAPER` on a Mac, `%APPDATA%\REAPER` on
Windows). Both are folders the Finder and Explorer hide, and the only sign
of where the file went was the status line at the foot of the window. The
tests write and read the file back against the mocked REAPER, so the
writing itself is tested; it has not been run inside REAPER here. The
likeliest reading is that it worked, into a hidden folder.

## Decision

**Play with REAPER** - a checkbox by Loop, ticked to begin with, saved
(`st.follow`). Ticked, when REAPER's transport starts playing, the idea
plays along on REAPER's clock rather than its own:

- **Where it starts**: on the bar the edit cursor is in (`Place.anchorQN`,
  `TimeMap_QNToMeasures`), taken when play starts. That is where Insert
  would put it, and a bar line keeps it in time with the project's own
  bars and drums whatever beat play was pressed on (pressed on beat 3, it
  comes in on its own beat 3).
- **The clock**: the project's quarter note at `GetPlayPosition2` - "the
  next audio block being processed", which is the block a note stuffed
  into the virtual keyboard now joins (`GetPlayPosition` is what is heard,
  an output latency later, so notes would come in late). The idea's notes
  are already in quarter notes, so REAPER's tempo and any tempo change are
  followed exactly.
- **Loop** on, it goes round in time with the project; off, it plays once
  from its bar and is silent before and after.
- **Following REAPER**: a loop region going round, or the play position
  moved, is a jump; what was sounding stops and the notes held across the
  new position are struck again (as REAPER's own MIDI chase does), so a
  chord in the middle of a bar is heard. A late wake-up of under a beat
  plays the notes it skipped, so nothing is lost to a slow frame.
- **A new idea while it plays** (New Idea, back, forward, a setting
  changed) takes over at the same place, in time (`Place.previewSwap`).
  On its own, Audition does the same now, unless Play new ideas starts the
  new idea from the top as before.
- **Never while REAPER records** (`GetPlayState` & 4): a monitored track
  recording its input would record the preview into the take.
- **Stop** (Audition's button reads Stop while it plays) silences it until
  REAPER's next play; **Audition** while REAPER plays joins in again, in
  time; unticking stops it; ticking while REAPER plays joins in.

**A click on the roll** plays from the nearest beat to it (`pianoRoll`
returns it; `Place.previewFrom`). With REAPER stopped, Audition starts
there, and the notes held across that beat are struck. With REAPER playing
along, REAPER's play position goes there (`SetEditCurPos` with seekplay -
the edit cursor moves too, as a click on REAPER's ruler does), the same
time round when Loop is on; then the jump is followed as above. The
alternative - moving only Good Idea - would put the idea out of step with
the project's bars.

**Save .mid to** - a row by the output buttons: **Project folder** (the
default: a `Good Idea` folder beside the saved `.rpp`, from `EnumProjects`;
REAPER's, said in the window, until the project is saved), **REAPER
folder** (1.0's), **Choose folder...**, and **Open folder**. The folder in
use is written in full underneath. Export's status line names the file and
says Open folder shows it.

- Choosing: REAPER itself has no folder chooser. Where the js_ReaScriptAPI
  extension is installed (`JS_Dialog_BrowseForFolder`), the system's; else
  `GetUserInputs`, a box to paste a path into (quotes and spaces taken
  off). Cancelling changes nothing.
- Opening: SWS's `CF_ShellExecute` where it is installed; else the
  system's own command through `ExecProcess` without waiting (`open` on a
  Mac, `explorer` on Windows, `xdg-open` elsewhere, by `GetOS`).
- The chosen folder is saved in its own ExtState key (`GoodIdea/exportDir`):
  a path can hold `;` and `=`, which the one-string state uses.

These are window and REAPER matters, not musical ones: they are not in
`I.SETTINGS`, are never rolled, and change no idea. `I.newState` and
`I.clampState` keep `follow` and `exportTo` as they keep `autoplay`.

## The REAPER calls

New in 1.17: `GetPlayState`, `GetPlayPosition2`, `TimeMap_QNToMeasures`,
`SetEditCurPos`, `EnumProjects`, `GetOS`, `ExecProcess`, `GetUserInputs`,
and the extensions' `CF_ShellExecute` and `JS_Dialog_BrowseForFolder`,
checked against the REAPER API functions page - ReaTeam/Doc's copy on
GitHub (generated by REAPER 6.09; reaper.fm is blocked from the container,
and the 7.79 page the user uploaded on 2026-10-01 was not in this
session). `GetOS` on newer REAPERs also says "macOS-arm64", which the
`mac` test catches. The mock gained them from those signatures; extension
functions read nil unless a test installs them, as in a REAPER without
SWS or js_ReaScriptAPI.

### 2026-10-07, later: checked against REAPER 7.79

The user uploaded the 7.79 API page again. Every `reaper.` call in the
scripts is on it with the signature used and mocked; the three that are not
are extensions' (`CF_ShellExecute`, `JS_Dialog_BrowseForFolder`,
`ImGui_GetBuiltinPath`), which the page does not list. Its `GetOS` adds
"macOS-arm64" to the 6.09 page's list: `openFolder` already took it for a
Mac (`find("mac")`), and a test now says so. No code changed.

## Consequences

- Once an idea is inserted, Play with REAPER plays it a second time over
  the inserted one. Said in its tooltip and the README rather than guessed
  at: there is no telling an inserted idea from any other MIDI.
- Timing is still a deferred script's: a note lands on the next wake-up
  (about thirty a second), up to some 30 ms late. Good enough to hear an
  idea against a track; for exact timing, insert it.
- Not yet run inside REAPER (as nothing here has been): the tests run
  the real window against mocked REAPER and ReaImGui.
