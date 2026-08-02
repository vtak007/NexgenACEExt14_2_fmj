# ACE bug report — false-positive "Illegal ProcessEvent Call Detected" on `Nexgen112N.NexgenClient.hasRight`

**To:** AnthraX (ACE anticheat author)
**From:** FMJ (FullMetalJacket) Deathmatch server admin
**Date:** 2026-08-01

## Summary

ACE is kicking legitimate, non-cheating players with `Illegal ProcessEvent Call Detected` on the stock
Nexgen function `Nexgen112N.NexgenClient.hasRight`. It is a **false positive**. It has occurred **169
times across 39 different players** over the logs we still have (Jan–Jul 2026), and continues on the
current ACE build. It is not tied to any one player, map, or ACE version. We would like `hasRight`
(a trivial client-side `simulated` string check) treated as trusted, or guidance on how to whitelist it.

## Environment

| Item | Value |
|---|---|
| Game | UT99 v469e (Release / x86) |
| Anticheat | ACE **v14e** now; historically **v13p** (bug present on both) |
| Admin mod | Nexgen **1.12N build 1200** (Letylove49 unofficial fork of Nexgen 1.12) |
| Core package | `Nexgen112N.u` |
| Gametype | DeathMatchPlus (also InstaGibPlus / IG+) |
| Other relevant mods | SmartSB124 (custom scoreboard), NexgenACEExt |

## The kick (representative block)

```
[ACEv14e]: KickReason.....: Illegal ProcessEvent Call Detected
[ACEv14e]: UFunction Name.: Nexgen112N.NexgenClient.hasRight
[ACEv14e]: Func Ptr.......: 6373E3E0
[ACEv14e]: Func Data......: Core.dll!?ProcessInternal@UObject@@QAEXAAUFFrame@@QAX@Z:0000
[ACEv14e]: Screenshot Status: Success   (a real screenshot capture — these are fully enforced kicks)
```

The flagged function is stock Nexgen and completely benign — it just checks whether a right-ID string is
present in the local player's rights string:

```unrealscript
simulated function bool hasRight(string rightID) {
    return instr(separator $ rights $ separator, separator $ rightID $ separator) >= 0;
}
```

Nexgen calls this constantly on the client (rights/idle checks run per-tick for every non-admin player),
which we believe is exactly why ACE's ProcessEvent-integrity check disproportionately blames it: it is
the most frequently-executing client-side `simulated` function, so it is the one most likely to be
"in flight" when the check misfires.

## Evidence it is a false positive (169-kick dataset)

- **Server-wide, not one player:** 39 distinct players kicked. Top: oskr ×71, w__keski ×13, Adenora ×18,
  then a long tail of one/two-time victims. These are regular, known-legit players.
- **Cross-version:** all 169 historical kicks are `[ACEv13p]`; current kicks are `[ACEv14e]`. The bug
  spans both ACE versions.
- **Map-agnostic:** 27 different maps (Phobos, CyberSpace, Temple0fTheWinds, Grinder, Viridian, Peak,
  1on1 maps, etc.). No correlation with any map or map package.
- **Transient / selective:** almost always **one** player is caught per game-end (144 game-ends kicked 1
  player, 11 kicked 2, 1 kicked 3). It is not a deterministic condition — it reads as a timing-dependent
  misfire, concentrated around the end-of-match / scoreboard transition.
- **Same signature every time:** identical `UFunction Name` and `Func Data` across all cases.

## What we have ruled out on our side

- **Not a specific player's machine/config** — 39 players across many different PCs, OSes, and NICs.
- **Not our custom mods** — kicks predate our current mod set and occur regardless. `hasRight` is stock
  Nexgen, unmodified.
- **No ACE admin knob to fix it** — we checked: `ACEFileList.txt` is a file-hash whitelist and
  `ACETweakList.txt` is a property (tweak) firewall; neither can whitelist a ProcessEvent function call.
  The `Illegal ProcessEvent` detector lives in `ACEv14e_S.dll` with no config exposed to admins.

## What we're asking

1. Can `Nexgen112N.NexgenClient.hasRight` (or Nexgen's per-tick rights/idle calls generally) be added to
   ACE's trusted/known-good set so this stops false-positiving?
2. If there is already an admin-side way to whitelist a specific UFunction from the ProcessEvent check,
   please point us to it — we could not find one.
3. If you need more data, we can provide: the full 169-entry kick list, complete individual ACE kick
   logs (with HWID/MAC/screenshot-success lines), and matching `server.log` excerpts.

Happy to test any ACE build or config change on the live server. Thanks for maintaining ACE.

---
*Reference for our own records: full dataset in `Nexgen_hasright_kicks.txt`; sample individual logs and
`server.log` retained. Nexgen 1.12N is the Letylove49 fork; `NexgenClient.hasRight` matches the
dscheerens/nexgen 1.12 lineage.*
