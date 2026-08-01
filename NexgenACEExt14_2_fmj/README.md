# NexgenACEExt14_2_fmj — unofficial IACEv14 recompile

## Build status: ✅ compiled & installed (2026-08-01)

Compiled clean against the real dependencies — **0 errors, 1 (pre-existing, harmless) warning**
(`NexgenACEExtClient.uc(242): 'A' : unreferenced local variable`, present in the original source and
left untouched). The IACEv14 interface turned out to be fully compatible with Sp0ngeb0b's IACEv12-era
source: all four IACE classes (`IACEActor`, `IACECheck`, `IACECommon`, `IACEConfigFile`) resolved with
no property/function mismatches, confirming the interface package did not change shape from v12 → v14.

Built with `ucc make` in the `C:\UnrealTournament` workspace against `IACEv14.u`, `Nexgen112N.u`
(build 1200, verified byte-identical to the server's copy), and stock 469 packages. The resulting
`NexgenACEExt14_2_fmj.u` (94,672 bytes) is committed at the repo root. Installed on the FMJ Deathmatch
server (`ServerPackages` + `ServerActors` added, the actor line after `Nexgen112N.NexgenActor`) and the
server restarted cleanly.

**This is a monitored experiment, not a confirmed fix** — see `repro-context.md`. The real test is
whether the `Illegal ProcessEvent Call Detected` / `NexgenClient.hasRight` kicks stop recurring now
that the plugin is live. Logs are being monitored.

The sections below document the original porting rationale and are kept for provenance.

## What this is

This is the source for **Sp0ngeb0b's NexgenACEExt version 2** (originally released for IACEv12), repackaged
under the name `NexgenACEExt14_2_fmj` so it can be compiled against `IACEv14.u` instead of `IACEv12.u`
for the FMJ Deathmatch server (ACE v14e / Nexgen 1.12N build 1200).

**No functional code was changed.** All 5 class files are byte-for-byte the same logic as the official
release — only the package folder name and header comments changed. This follows the original author's
own README FAQ, which explicitly permits recompiling for a custom version if he can't be reached, provided:
credit stays intact (it does, see file headers) and the package uses a unique suffix rather than an
official-looking version bump (hence `_fmj` rather than `NexgenACEExt14_3`).

**Before using this in production, the right move is still to try contacting Sp0ngeb0b first**
(spongebobut@yahoo.com / www.unrealriders.eu) to ask if an official IACEv14 build already exists or if
he's willing to do one — that's what his own README asks for.

## Why this might "just work"

The plugin only touches four classes from ACE's small public interface package: `IACEActor`, `IACECheck`,
`IACEConfigFile`, `IACECommon` (plus `ChallengeHUD`). These are a stable, versioned interface package
that ACE ships specifically so third-party mods don't need ACE's real source — that's the whole point of
having a separate `IACEv##.u` file per ACE version. The original author already shipped this exact same
source as two separate packages (`NexgenACEExt11_2` for IACEv11, `NexgenACEExt12_2` for IACEv12) with
**no code differences between them** — just a different link target. That's reasonably strong evidence the
interface didn't change shape between those versions, which is a good sign it may not have changed shape
by v14 either.

**This is not verified.** If AnthraX added, renamed, or removed fields/functions on those interface classes
between v12 and v14, the compiler will simply fail with unresolved-property errors — which is actually the
good outcome, since it tells you exactly what to fix rather than silently misbehaving.

## What's still needed to actually produce a working `.u`

Compiling this requires `ucc.exe` (or the Linux `ucc-bin` if compiling on the VPS directly) with access to
the following packages already present as compiled `.u` files, since the compiler needs to resolve every
class this code extends or references:

- `Core.u`, `Engine.u`, `Botpack.u` — standard UT99 packages
- `UWindow.u`, `UMenu.u` — for the windowing classes (`UWindowSmallButton`, `UWindowComboControl`,
  `UWindowDynamicTextArea`, `UWindowCheckbox`, `UWindowDialogControl`)
- `Nexgen112N.u` (or whatever the compiled core Nexgen package is named on this server) — for
  `NexgenExtendedPlugin`, `NexgenClient`, `NexgenPanel`, `NexgenUtil`, `NexgenExtendedClientController`,
  `NexgenSharedDataContainer`, `NexgenSharedDataSyncManager`, `NexgenTextFile`, `NexgenSimplePlayerListBox`,
  `NexgenPlayerList`, `NexgenDummyComponent`, `NexgenEditControl`, `NexgenHUDExtension`, `NexgenContentPanel`
- `IACEv14.u` — the actual ACE v14 interface package (this is the one piece that determines whether this
  compiles cleanly or needs edits)

None of these are available to me in this session — I only have your server's `.ini` config files and log
output, not the compiled `System` folder. I can't produce a working `.u` binary without them.

## Two ways to finish this

**Option A — you compile it.** Copy the `Classes` folder to
`<server>/System/NexgenACEExt14_2_fmj/Classes/` on the actual server (or a local UT99 install with the
same package versions), then from the `System` folder run:

```
ucc make -ini=UnrealTournament.ini
```

after adding to `UnrealTournament.ini` under `[Editor.EditorEngine]`:

```
EditPackages=NexgenACEExt14_2_fmj
```

Fix whatever the compiler flags (most likely spot, if anything: `IACEv14`-specific property/function
mismatches). Once it compiles clean, follow the same server-install steps as the original plugin (add
`ServerPackages=NexgenACEExt14_2_fmj` and `ServerActors=NexgenACEExt14_2_fmj.NexgenACEExt` — the actor line
must come after `ServerActors=Nexgen112N.NexgenActor` — then restart).

**Option B — send me the dependency `.u` files.** If you drop `Core.u`, `Engine.u`, `Botpack.u`, `UWindow.u`,
`UMenu.u`, your Nexgen core `.u`, and `IACEv14.u` from the server's `System` folder into the shared folder,
I can fetch a Linux `ucc-bin` (OldUnreal's 469 dedicated server build ships one) and attempt the actual
compile here, iterate on any errors, and hand you back a tested `.u` ready to install.
