# Desktop hung out of memory, nothing could save it

2026-07-30 ~17:00. Mostly fixed; `kernel.sysrq` still open.

**Symptom** Desktop froze, power button the only way out, four agent sessions
lost. **The OOM killer never fired** - no `oom-kill:` line in the whole boot,
the signature of swap thrash.

**Root cause** A review subagent ran `ugrep -oiE '.{0,70}(...).{0,70}'` over
agent transcripts in `/tmp/claude-*`: JSONL with enormous single lines, and
`-o` collects every match per line. Measured 17.6 GB RSS, 22.7 GB after 20 s,
23.8 GB a minute later, on a 31 GB machine; killing it dropped usage 21 GB ->
4.1 GB. Resuming that subagent replayed the same search: after this failure an
agent must be restarted, never resumed. Three missing defences: no `earlyoom`
(installed 17:53:43, after the hang); zram 4 GB; `kernel.sysrq = 16` allows
only `sync`.

**Fix** `earlyoom` is now an `always: true` host feature enabled by
`30-system`, which also pins `zram-size = ram / 2`; agents and containers are
capped by `50-agents-budget.conf` (12G/16G). `kernel.sysrq` is untouched.
Ruled out: the Whisper model swap (done 14:30), NVIDIA (`NVRM: Out of memory`
all 11:00-13:43), containers (none breached 8 GB).

**Recheck** `systemctl status earlyoom`; `zramctl` (~15G); `sysctl
kernel.sysrq` (still 16).
