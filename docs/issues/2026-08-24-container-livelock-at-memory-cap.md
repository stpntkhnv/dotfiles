# `stellium` livelocked at its 8g cap, with no OOM kill

2026-08-24 ~15:40-15:55, again 2026-08-25 ~13:53-16:01. Status: open.

**Symptom** Terminals in the `stellium` distrobox stopped responding while the
container looked healthy: `Up 6 hours`, no process dead, `oom_kill 0`. Inside,
`redis-server`, `npm run dev` and three `claude` processes sat in `D` state on
`folio_wait_bit_common`.

**Root cause** Reclaim livelock in the container cgroup, not a deadlock.
`memory.current` pinned at `memory.max` (8.589 GB), of which 6.65 GB `anon`
and 1.07 GB `shmem` - undroppable, both need swap. Swap-out was failing
(`memory.swap.events` `fail 23222`): zram is RAM-backed and the host had
712 MiB free. Reclaim could then only take file pages - the code pages of
dotnet, node, sqlservr, 1.19 GB left, 34 MB active - which refaulted
instantly: 1.6M pages/s scanned (~6.3 GB/s), 4664 major faults/s,
`workingset_refault_file` 986 MB, `memory.events` `max 21403064`. Dropping a
code page always counts as successful reclaim, so OOM was never declared,
nothing was killed, and it could not end on its own. PSI `full avg10=48.5`:
half of all wall time every task in the container was stalled. Trigger: two
`dotnet` builds at 15:40:41 and 15:41:38 added 22 MSBuild nodes and a 1.13 GB
`VBCSCompiler` on top of an Aspire stack, SQL Server, 36 node processes and 5
`claude` sessions live since 10:17.

`earlyoom`, installed after
[2026-07-30-desktop-hang-out-of-memory.md](2026-07-30-desktop-hang-out-of-memory.md),
cannot see this: it polls global `/proc/meminfo`, which showed 8.6 GB
available and 43% swap free against its 10%/10% defaults. The cgroup was at
its ceiling, and `earlyoom` is cgroup-blind by design.

**Fix** None yet. On 08-24 it cleared itself at ~15:55 when both builds
finished. On 08-25 it did not: one `dotnet build` of a single csproj, started
13:53:46, was still running 2h07m later with `max` at 241M and PSI
`full avg10=66`. Killing that build and its 11 nodes - `SIGTERM` was enough,
freeing ~904 MB - dropped reclaim to 0 MB/s and PSI to `full avg10=0.93`
within seconds, and `podman exec` answered in 87 ms again. So waiting is not a
fix: a build inside the livelock can stall indefinitely, because it is both
the victim and the fuel. The container settles back at ~7.8 GB of 8.0 GB
either way, so the cliff is unmoved.

The mitigation shipped on 08-25 is `DOTNET_gcServer=0`,
`DOTNET_GCConserveMemory=5` and `MSBUILDDISABLENODEREUSE=1` for containers in
`home/dot_bashrc.tmpl` ([dev-tools.md](../dev-tools.md)), carried on the `<ctx>`
entry aliases because `distrobox enter <ctx> -- <cmd>` reads no rc file and the
builds here are launched by agents, not typed. It lowers the cost of each
process; it does not raise the ceiling, and it reaches only processes started
after the change - the Aspire services from 08-24 kept their 12 heaps.

**Recheck** Under load, the pair that separates livelock from ordinary
pressure is a climbing `max` with `oom_kill 0`:

```sh
CG=$(podman inspect stellium --format '{{.State.CgroupPath}}')
cat /sys/fs/cgroup"$CG"/memory.events /sys/fs/cgroup"$CG"/memory.pressure
```
