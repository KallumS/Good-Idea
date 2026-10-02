# Starting a fresh session

Paste the prompt below into a new Claude Code session on this repository
(branch `claude/pensive-cannon-snl685`, or `main` once it is merged). It is
kept here so it survives the session that wrote it; update it at the end of
each session.

---

I'm continuing work on **Good Idea**, my ReaScript for REAPER that makes
ideas for starting a track - Motifs, Phrases, Measures and Drums -
calculated from the rules of music and put into the project as MIDI. I'm a
musician, not a programmer, so please explain everything in musical terms.

Before you change anything, please:

1. Read `CLAUDE.md` all the way through - especially "The one idea" (an
   idea is a number, and old idea numbers must keep giving the same idea),
   "Releasing" (the order every change is done in) and "What has been
   learned" (mistakes already made once).
2. Skim `docs/decisions/README.md` and the latest session log in
   `docs/sessions/` to see where we left off. We are at version 1.6.
3. Install Lua if it is missing (`apt-get install -y lua5.4`), run
   `tools/test.sh` and confirm everything passes before you start.
4. Print a few ideas with `tools/demo.lua` so you know what it sounds like
   now, e.g. `lua5.4 tools/demo.lua Measure 3 1 4 4 colour=Mixed`.

How I like the work done:

- Every change is a release: read the demo before and after, run the tests
  and the deep sweep (`GOOD_IDEA_SWEEP=40 tools/test.sh`, in the
  background), write tests for what each new setting's hint promises, and
  prove each one bites with `tools/bite.sh` - breaking the code on purpose
  and watching the test fail. Then bump the version in `Good Idea.lua`,
  write a decision record, update CLAUDE.md, the README and the session
  log, commit, add the new `<version>` to `index.xml` pinned to that commit,
  and push. Don't open a pull request unless I ask.
- Measure rather than guess (how often something happens, per idea and per
  chord or beat), and tell me the numbers in plain words.
- If you can settle a choice with a sensible default, do it and tell me
  what you chose; only ask me about things that are genuinely mine to
  decide.
- Keep new settings at the end of the settings list, off or neutral by
  default where they would change old ideas, with their own dice.
- I've uploaded Educational Materials (Open Music Theory pages) before; if
  a question is about how music works, check them or the web, and tell me
  your sources.

Things left open that we might pick up (none of them asked for yet): trying
it inside REAPER; a separate Drop 4 voicing; out-of-key colour chords;
flavours for Triads or Sevenths; ghost notes in drum ideas; a drum groove
matched to a Measure's bass; pull for the bass.

What I'd like to do next: **[describe it here]**
