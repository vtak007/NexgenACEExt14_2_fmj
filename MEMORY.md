# MEMORY — NexgenACEExt14_2_fmj

Persistent project memory. Read at the start of every session. Update before every commit.

## CONFIRMED ROOT CAUSES

- **IACE interface is stable v12 → v14.** Sp0ngeb0b's IACEv12-era source compiled against `IACEv14.u`
  with **0 errors** (2026-08-01). All four IACE classes used (`IACEActor`, `IACECheck`, `IACECommon`,
  `IACEConfigFile`) resolved with no property/function mismatches. The `.uc` files reference these
  classes *unqualified* — there are no hard-coded `IACEv12` package references (the 15 `IACEv` grep
  hits are all header-comment text). So the only thing that made this a "port" was the package name.

- **The `hasRight` kick is a SERVER-WIDE, CROSS-VERSION, TRANSIENT ACE false-positive** (established from
  the 169-kick dataset `Nexgen_hasright_kicks.txt`, 2026-08-01). Signature always identical: `Illegal
  ProcessEvent Call Detected` / `Nexgen112N.NexgenClient.hasRight`. Hard data from 169 kicks (Jan–Jul
  2026; user says the pattern goes back to ~Mar 2025):
  • **Server-wide, not player-specific** — 39 distinct players. oskr 71× (42%), w__keski 13×, Adenora
    (both spellings) 18×, long tail. Flux is NOT in this v13p-era set. Rules out any one player's
    machine/config/hardware.
  • **Cross-version** — all 169 are `[ACEv13p]`; today's flux kicks are `[ACEv14e]`. The bug spans ACE
    v13p → v14e. The v14 upgrade neither caused it nor could fix it. Recent changes are not the cause.
  • **Map-agnostic** — 27 different maps (Phobos 27, CyberSpace 14, Temple 11, Grinder 10, …). Not a
    bad map/package.
  • **Selective / transient — usually ONE victim per game-end** — 144 game-ends kicked exactly 1
    player, 11 kicked 2, 1 kicked 3. So it is NOT a deterministic "everyone but the winner" rule; it is a
    transient misfire catching (usually) a single non-winner.
  Best-supported model = the original `repro-context.md` theory, now data-backed: a transient ACE
  ProcessEvent-integrity false-positive that blames `hasRight` because it is the most frequently-executing
  client-side (`simulated`) function, catching whichever one player is mid-`hasRight` when the trigger
  fires (concentrated around game-end / scoreboard). Detection is client-side; `server.log` shows only the
  aftermath (`Connection timed out after 60s`). Exact call site is in the **Nexgen112N (Letylove49) fork
  core** (compiled-only, not confirmed to the line).

- **HYPOTHESIS (UNVERIFIED): the winner/leader is exempt.** From flux's live test he was not kicked when
  leading at an early-end. Plausibly explained by the transient model (winner's victory-state client
  isn't calling `hasRight` at that instant) rather than a hard rule. NOT confirmed and softly
  counter-indicated: two `1on1` sessions (`Sph3res-v2`: telfakiu+w__; `Lego][`: Adenora+oskr) each had
  2 simultaneous kicks — if those were true 2-player duels the winner was NOT exempt, but "1on1" is only
  a map name and the server has 12 slots, so player count is unknown. Do not treat winner-exempt as fact.

- **No fix exists in NexgenACEExt, ACE config, or Nexgen.ini.** Proven: (a) 3 identical kicks with the
  plugin confirmed-loaded (`server.log:223 AutoConfig Added Package: NexgenACEExt14_2_fmj`); (b) ACE
  exposes only two admin lists and neither whitelists function calls — `ACEFileList.txt` (file-hash
  whitelist: `FileName·Size·MD5·Identifier·Hacked?`) and `ACETweakList.txt` (property firewall:
  `ALLOW/DENY·Class·Property·Condition·Type·Value`). The `Illegal ProcessEvent` detector is hardcoded
  native code in `ACEv14e_S.dll` with no config knob (verified by reading the DLL's embedded format
  strings). Realistic fixes: patch the Letylove49 fork (need source), or report to ACE author (AnthraX).
  NOTE: the "end matches naturally" workaround is INVALID — kicks happen on full natural games too (see
  corrected root cause above). The only observed safe case is flux himself winning/leading.

## RULED-OUT THEORIES

- **"The port needs source edits for v14."** Ruled out — it compiled unchanged. Source stays
  byte-for-byte identical to the official v2 release (per the author's README FAQ); do **not** edit
  the `.uc` to silence the one pre-existing warning.
- **NexgenACEExt fixes the `hasRight` kicks.** RULED OUT (was "monitored experiment"). 3 identical
  kicks with the plugin confirmed-loaded. It never touched `NexgenClient.hasRight`. Dead lead — do not
  revisit.

- **Scoreboard renders through Nexgen's HUD wrapper (SmartSB → NexgenHUDWrapper).** RULED OUT — this
  was an earlier wrong theory. `Nexgen.ini:63 useNexgenHUD=False`, and `SmartSB.uc:626-629`/`:668-670`
  only force `NexgenHUDWrapper` when `useNexgenHUD ~= True`. So SmartSB uses its own `SmartSBScoreBoard`
  and never routes through Nexgen's HUD. The scoreboard is just the visible marker of game-end; the
  `hasRight` call is Nexgen's own client-side end handling. SmartSB source has zero `hasRight` refs.

- **Idle-kick (`maxIdleTime`) causes it.** RULED OUT (this was `repro-context.md`'s original working
  theory). Kicks cluster at game-end scoreboard, not after idle time during play; the simultaneous
  double-kick fits one game-end instant, not independent idle timers. Disabling `maxIdleTime` would not
  help — do not pursue.

- **ACE has an admin whitelist for the ProcessEvent check.** RULED OUT — verified against `ACEv14e_S.dll`
  and both list files. See CONFIRMED ROOT CAUSES for the two lists that DO exist (neither applies).

- **Admin force-end (vs natural win) is the trigger.** RULED OUT / WRONG earlier read (corrected
  2026-08-01 by user). Kicks have happened for 2 years on FULL games to the 30-frag limit; early-ends
  were only done to save time, not a cause. The real differentiator is winner/leader (exempt) vs
  non-winner (kicked), NOT how the match ends. Consequently the `enableNexgenStartControl=False`
  experiment's premise is undermined — but running it is still informative: if flux is kicked ending a
  game naturally while not leading, that positively confirms match start/end control is irrelevant.

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

Plugin compiled, installed on FMJ Deathmatch, confirmed loaded. **It did NOT stop the kicks** — that
lead is closed. Root cause (data-backed 2026-08-01 via 169-kick dataset): a **server-wide, cross-version
(ACE v13p→v14e), map-agnostic, transient ACE ProcessEvent false-positive** on `NexgenClient.hasRight`,
usually catching one non-winner per game-end. NOT flux-specific, NOT caused by the v14 upgrade, NOT
fixable via the plugin, ACE config, or `Nexgen.ini`. "Winner is exempt" remains an unverified hypothesis.
Because it spans ACE versions and all players, the **ACE-author (AnthraX) report is now the strongest
route**; a Letylove49 fork patch is the alternative.

**EXPERIMENT IN PROGRESS (option #1):** user set `enableNexgenStartControl=False` to test whether
Nexgen's game-control end sequence is what triggers the kick. Awaiting a test session's logs.
Test protocol: get flux in, a couple of frags, **admin force-end** the match (the exact prior trigger)
+ one natural frag-limit finish as control; watch flux's ACE log. Result reading: kicks stop → start-
control end path confirmed as cause (then decide if `False` is an acceptable permanent setting); kicks
persist (same `hasRight` / `6373E3E0` signature) → start-control ruled out too, move to #2/#3. Caveat:
`enableNexgenStartControl` primarily governs match START (ready-up/hold); that it also changes the END
path is the hypothesis under test, not a certainty — don't leave it off permanently until confirmed.

**Other next options** (if #1 fails):
2. Obtain Letylove49 Nexgen112N `.uc` source → trace the game-end `hasRight` call (why the winner's
   victory/end state skips it but non-winners don't) → assess core patch.
3. Report the false-positive to ACE author (AnthraX).
(Note: "avoid force-ends / end naturally" is NOT a valid workaround — full natural games kick too.)

**Reference files in repo root for this investigation** (all `.gitignore`d): `Nexgen.ini`,
`ACETweakList.txt`, `ACEFileList.txt`, `ACEv14e_S.dll` + ACE `.u` packages, `server.log`, the four
`[ACE]...flux.log` kick logs, and `Nexgen_hasright_kicks.txt` (169-kick historical dataset: filename
listing + the `hasRight` UFunction line for each; fields per name = date, map, capture-index N, player).
