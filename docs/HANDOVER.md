# Starting a fresh session

Paste the prompt below into a new Claude Code session on this repository
(branch `claude/pensive-cannon-snl685`, or `main` once it is merged). It is
kept here so it survives the session that wrote it; update it at the end of
each session.

---

I'm continuing work on **Good Idea**, my ReaScript for REAPER that makes
ideas for starting a track - Motifs, Phrases, Measures and Drums -
calculated from the rules of music and put into the project as MIDI. I'm a
musician, not a programmer, so please explain everything in musical terms
(what I'll hear, which bars, which chords), with numbers you've measured.

Where we are: **version 1.15**, published in `index.xml`. Since 1.6 it has
been brought in line with the theory books I uploaded (part-writing by the
book, shaped velocity, applied chords, deceptive and evaded cadences, more
forms, named progressions and galant schemata, suspensions and
appoggiaturas, a second voice in thirds or sixths, Pedal/Offbeat/Fill chord
styles, clave and tresillo rhythms, 6/9 and power chords, a key change for
the last section, the minor key's major V, a reggaeton beat; and since 1.13
flavours with every colour, a Drop 4 voicing, ghost notes in the drums, the
bass lying back with pulled chords, the galant schemata in minor, a truck
driver that nearly always changes gear, and chromatic chords - the
Neapolitan, the augmented sixths, a passing diminished seventh). In 1.13 the
engine took over three choices to keep the window simple: the progression
(walk or a named one, half and half), the part-writing (always by the book)
and the form (each about one idea in ten) are decided under the hood and not
shown. Old idea numbers no longer need to give the same idea as before - no
one is using the script yet - but the same number with the same settings
must still give the same idea.

Before you change anything, please:

1. Read `CLAUDE.md` all the way through - especially "The one idea" (an
   idea is a number), "Releasing" (the order every change is done in) and
   "What has been learned" (mistakes already made once - it is long
   because each of them cost time).
2. Skim `docs/decisions/README.md` (latest: 0027) and the end of the latest
   session log in `docs/sessions/` to see where we left off.
3. Install Lua if it is missing (`apt-get install -y lua5.4`), run
   `tools/test.sh` and confirm everything passes before you start.
4. Print a few ideas with `tools/demo.lua` so you know what it sounds like
   now, e.g. `lua5.4 tools/demo.lua Measure 3 1 4 4 colour=Mixed`.

How I like the work done:

- Every change is a release: read the demo before and after, run the tests
  and the deep sweep (`GOOD_IDEA_SWEEP=40 tools/test.sh` on a snapshot
  copy, in the background - it takes a while and has found real bugs every
  release), write tests for what each new setting's hint promises, and
  prove each one bites with `tools/bite.sh` - breaking the code on purpose
  and watching the test fail. Then bump the version in `Good Idea.lua`,
  write a decision record, update CLAUDE.md, the README and the session
  log, commit, add the new `<version>` to `index.xml` pinned to that commit
  with a changelog in my words, and push. Don't open a pull request unless
  I ask.
- Measure rather than guess (how often something happens, per idea and per
  chord or beat), and tell me the numbers in plain words. Check any claim
  about what changed before it goes in a changelog.
- If you can settle a choice with a sensible default, do it and tell me
  what you chose; only ask me about things that are genuinely mine to
  decide. Where the books disagree with each other, ask me; where they
  agree, follow them.
- The window is getting full: prefer the engine deciding something to a
  new row of buttons, unless I ask for a control.
- New settings go at the end of the settings list, with their own dice,
  drawing nothing when off.
- I've uploaded Educational Materials (Hutchinson's theory textbook, Open
  Music Theory pages and orchestration books); `docs/READING.md` has notes
  on all of them (everything in its first section is now done). If a
  question is about how music works, check those notes, the materials or
  the web, quote the source's own words, and tell me where they're from.

Things left open that we might pick up (none of them asked for yet; the
full list is at the end of CLAUDE.md): trying it inside REAPER; the
common-tone diminished seventh and the Swiss sixth; a drum groove matched
to a Measure's bass; per-drum choices in drum ideas; the Ponte, Aprile and
Pastorella schemata; bringing the Form row back if I want to pick a form
myself.

What I'd like to do next: **[describe it here]**
