# NexgenACEExt14_2_fmj — Project Instructions

Unofficial recompile of Sp0ngeb0b's **NexgenACEExt version 2** (originally for IACEv12) against
**IACEv14**, for the FMJ Deathmatch server (ACE v14e / Nexgen 1.12N build 1200). No functional
source changes — package renamed to `NexgenACEExt14_2_fmj` only. See `NexgenACEExt14_2_fmj/README.md`.

## Key Files

| File | Purpose |
|---|---|
| `NexgenACEExt14_2_fmj/Classes/NexgenACEExt.uc` | Server-side plugin actor (`extends NexgenExtendedPlugin`); bridges Nexgen ↔ ACE |
| `NexgenACEExt14_2_fmj/Classes/NexgenACEExtClient.uc` | Per-client controller (`extends NexgenExtendedClientController`); receives ACE HWID/MAC |
| `NexgenACEExt14_2_fmj/Classes/NexgenACEExtHud.uc` | HUD extension (`extends NexgenHUDExtension`); crosshair-scaling fix |
| `NexgenACEExt14_2_fmj/Classes/NexgenACEExtAdminPanel.uc` | Nexgen admin config panel (`extends NexgenPanel`) |
| `NexgenACEExt14_2_fmj/Classes/NexgenACEExtClientConfig.uc` | Client-side ACE config panel (`extends NexgenPanel`) |
| `NexgenACEExt14_2_fmj/README.md` | Build status, porting rationale, install steps |
| `NexgenACEExt14_2_fmj/repro-context.md` | The `hasRight` ACE-kick problem this plugin is meant to help with |
| `NexgenACEExt14_2_fmj.u` | Compiled output (94,672 bytes) — installable package |
| `MEMORY.md` | Persistent project memory (root causes / ruled-out / conventions) |

The seven other root-level `.u` files (Botpack, Core, Engine, UMenu, UWindow, Nexgen112N, IACEv14)
are compile dependencies only and are `.gitignore`d — they are not part of this plugin.

## Build

Compiled in the `C:\UnrealTournament` UCC workspace (sibling-of-System source layout), not from this
repo directly. Steps: copy `IACEv14.u` into `System`, place `Classes/` at `C:\UnrealTournament\NexgenACEExt14_2_fmj\Classes\`,
use an isolated build ini (`EditPackages` swaps `IACEv13`→`IACEv14`, drops `SmartSB124` to avoid a
dual-IACE `IACEActor` name clash, appends `NexgenACEExt14_2_fmj`), then `ucc make -ini=<buildini>`.
