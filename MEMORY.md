# MEMORY — NexgenACEExt14_2_fmj

Persistent project memory. Read at the start of every session. Update before every commit.

## CONFIRMED ROOT CAUSES

- **IACE interface is stable v12 → v14.** Sp0ngeb0b's IACEv12-era source compiled against `IACEv14.u`
  with **0 errors** (2026-08-01). All four IACE classes used (`IACEActor`, `IACECheck`, `IACECommon`,
  `IACEConfigFile`) resolved with no property/function mismatches. The `.uc` files reference these
  classes *unqualified* — there are no hard-coded `IACEv12` package references (the 15 `IACEv` grep
  hits are all header-comment text). So the only thing that made this a "port" was the package name.

## RULED-OUT THEORIES

- **"The port needs source edits for v14."** Ruled out — it compiled unchanged. Source stays
  byte-for-byte identical to the official v2 release (per the author's README FAQ); do **not** edit
  the `.uc` to silence the one pre-existing warning.
- **NexgenACEExt is a confirmed fix for the `hasRight` kicks.** NOT established. NexgenACEExt does not
  touch `NexgenClient.hasRight` or Nexgen's idle-kick system (see `repro-context.md`). Installing it is
  a *monitored experiment*, not a proven fix. Do not describe it as the fix until logs confirm the
  `Illegal ProcessEvent Call Detected` / `NexgenClient.hasRight` kicks stop recurring.

## PROJECT CONVENTIONS

- **Compile workspace**: `C:\UnrealTournament` (live UCC env), NOT the `_Local` weekly backup snapshots
  under `D:\UnrealTournament_Local\...` and NOT the repo directly. Source packages live as siblings of
  `System` (e.g. `C:\UnrealTournament\SmartSB124\Classes`).
- **Dual-IACE clash**: only ONE IACE package may be in `EditPackages` when compiling, or `IACEActor`
  resolves ambiguously. The build ini swaps `IACEv13`→`IACEv14` and drops `SmartSB124` (which imports
  IACEv13). Live `UnrealTournament.ini` is left untouched — use a separate `-ini=<buildini>`.
- **Verified dependency**: server's `Nexgen112N.u` (build 1200) is MD5-identical to the compile copy
  (`912b5aa4b998a26471265d8b1b437825`, 1,698,534 bytes).
- **`.gitignore`d**: the 7 stock/dependency `.u` files at repo root (Botpack, Core, Engine, UMenu,
  UWindow, Nexgen112N, IACEv14). Only `NexgenACEExt14_2_fmj.u` is kept.
- **Install lines** (FMJ server `System`): `ServerPackages=NexgenACEExt14_2_fmj` and
  `ServerActors=NexgenACEExt14_2_fmj.NexgenACEExt` — the actor line MUST come *after*
  `ServerActors=Nexgen112N.NexgenActor`.
- **Pre-commit doc rule** (from global CLAUDE.md): update `README.md`/`CLAUDE.md` only after the change
  is tested and the user has approved. Docs are the final step before commit.

## STATUS (2026-08-01)

Compiled, installed on FMJ Deathmatch, server restarted cleanly, everything looks good.
**Open**: monitoring server logs for recurrence of `NexgenClient.hasRight` ACE kicks.
