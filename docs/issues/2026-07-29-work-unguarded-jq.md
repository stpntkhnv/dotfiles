# Unguarded jq extractions in `work`

Found 2026-07-29. Status: fixed 2026-07-30.

**Symptom** Never seen live; found by audit. Under `set -euo pipefail` a jq
exit 2 inside a command substitution kills the script mid-loop, so remaining
contexts never open and `exec herdr` never runs.

**Root cause** Three jq calls in `home/dot_local/bin/executable_work.tmpl`
lacked `|| true`: the `count == 1` branch of `first_tab_pane`, and the
`workspace_id` / `root_pane.pane_id` extractions in the create-workspace
branch. `// empty` guards against `null`, not against invalid JSON. The other
six jq uses in the file were checked and are fine.

**Fix** `|| true` at all three sites, deliberately without `2>/dev/null` so
jq's own error stays on stderr. Verified with a stub jq failing on exactly the
second extraction: before rc=2 and script dead, after rc=0; with real jq both
versions rc=0, so the test does not pass by itself. No real input reproduces
it - the same `$panes` and `$tab` were parsed successfully one line above.

**Recheck** `grep -n 'jq -r' home/dot_local/bin/executable_work.tmpl` - every
hit outside an `if` condition ends in `|| true`.
