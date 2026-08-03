# CLAUDE.md

This repo is a personal Arch Linux configuration on chezmoi: packages, home
configs, install and setup scripts, and - the complex part - isolation of
several work contexts inside one browser via distrobox and network namespaces.
Docs live in `docs/`, split by subsystem and bound to the code machine-readably
through the `covers` frontmatter in each doc plus the generator
`tools/gen-catalog.sh`. Start at [`docs/README.md`](docs/README.md), it is the
map.

The command worth remembering: `tools/gen-catalog.sh --check` runs every
coverage check and writes nothing. Without `--check` it also regenerates
`docs/catalog.md`.

## Main rule: code and docs change together

**A change is not finished until the docs describe the repo correctly again.**
Not a follow-up task, not the next session's problem: editing a file and
editing the docs that describe it are one change and one commit. The docs cost
more than the code and are valuable exactly because they can be trusted without
re-checking; one paragraph that drifts from the code takes that property away
from the whole catalogue, because from the outside there is no way to tell
which paragraph went stale.

Run this on every task, however small it looks:

1. **Look at what actually changed** - `git diff` and `git status`, not your
   memory of what you set out to do.
2. **Find every doc that describes it.** For a file: the `docs/*.md` whose
   `covers.paths` lists it (rule 1). For a feature: the doc whose
   `covers.features` holds its key (rules 2 and 3). Then `grep` for the file
   name, feature key, function, unit, port, package - docs quote code verbatim
   and cross-reference each other, so mentions live where `covers` promised
   nothing.
3. **Fix every doc you found, not the first one.** A quote that disagrees with
   the code is worse than no quote: it looks verified.
4. **Run `tools/gen-catalog.sh --check`** and get a clean exit. If you touched
   the feature catalogue or any `covers` header, first run it without the flag
   (rule 4).
5. **Do not call the task done before 1-4 are done.** "Code is ready, docs
   later" is an open task, not a finished one.

Two things to get right about this.

**The check does not replace reading.** `gen-catalog.sh` knows feature and path
coverage and link integrity; it knows nothing about meaning. A script can
change behaviour completely, its doc can lie in every paragraph, and the check
still exits `0`. It also has three named blind spots, listed in
[`docs/operations.md`](docs/operations.md): a doc mentioned as plain text
rather than as a markdown link is invisible to it; the root `README.md` and
`docs/issues/*.md` are not read as link sources; a file under `home/` that was
never `git add`ed does not count as uncovered.

**"Too small to matter" is a verdict, not an assumption.** If a change really
touches nothing described - a typo in a comment nobody quotes, reordered lines
with no behaviour change - leave the docs alone. But decide that after step 2,
not instead of it: counts, verbatim quotes, unit names, ports and package names
are scattered across dozens of documents, and a one-line edit routinely lands
in three of them.

## Rules

1. **Touched a file under `home/` - update every doc that lists it.** Find all
   `docs/*.md` with that path in `covers.paths` and fix each. One script may
   legitimately appear in several docs: `run_onchange_before_30-system.sh.tmpl`
   sets up the keyboard layout, zram and the firewall at once.
2. **Added a feature to `home/.chezmoidata.yaml` - give it a doc.** Put its key
   in some doc's `covers.features` or write a new doc. An uncovered feature is
   an error: the generator finishes its report and then exits `1`.
3. **Editing an existing feature block** (packages, `scope`, `needs`, `label`)
   - the edit goes to the doc whose `covers.features` holds that key, not to
   `how-it-works.md`. Rule 1 gives no hint here: `.chezmoidata.yaml` is one
   file and holds every feature, while `how-it-works.md` describes only the
   machinery of the catalogue.
4. **After editing the feature catalogue or any `covers` header, run
   `tools/gen-catalog.sh`** without `--check` and commit the resulting
   `docs/catalog.md`. That file is never hand-edited: the generator is its only
   source, and manual edits vanish on the next run.
5. **Worked around someone else's bug - record it in
   [`docs/workarounds.md`](docs/workarounds.md).** The row carries the evidence
   in one of the four states the file defines, plus the check that shows
   whether the bug is still alive. Without it the workaround reads as repo
   logic and outlives its cause by years. The registry holds the *outcome*;
   `docs/issues/` holds the *investigation*. Start an investigation log and the
   subsystem doc links to it, or nobody will ever see it.
6. **Back a claim about this repo with a file plus an anchor** - a function
   name, a heading, a short unique fragment - never a bare line number. Line
   numbers rot on the first unrelated edit above them.
7. **Docs are written for agents, in English, to the standard in
   [`docs/STYLE.md`](docs/STYLE.md).** Dense, factual, no tutorials about
   standard technology, 1.5-8 KB per doc, fixed section skeleton. A doc is an
   index and a memory, not a second copy of the code: point at the file instead
   of pasting it, and spend the bytes on what cannot be re-derived - rationale,
   rejected alternatives, dated evidence, verification commands.
8. **Do not strip the explanatory comments in `home/.chezmoiscripts/` and
   `home/.chezmoidata.yaml`.** They are deliberate. If a global "no comments in
   code" rule applies to you elsewhere, it does not apply here: comments like
   why `distrobox` is created with `--userns keep-id`, or why the socket lives
   in `/var/lib/wsproxy` rather than `/mnt`, save the next reader a day of
   rediscovery.
