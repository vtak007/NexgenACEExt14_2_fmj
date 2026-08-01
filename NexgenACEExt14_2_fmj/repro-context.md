# Repro context: the ACE kick this plugin is meant to help with

## Background

FMJ Deathmatch server, UT99 v469e, ACE v14e, Nexgen 1.12N build 1200 ("Letylove49" unofficial fork).
Two players (flux and DaSnaksta) were kicked by ACE within the same second, on the same map, for the
same reason: `Illegal ProcessEvent Call Detected` on `Nexgen112N.NexgenClient.hasRight`. Both logs
include a successful screenshot capture, confirming these were real, fully-enforced kicks - not just
logged detections.

## Kick log 1 — flux

```
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                                  Player Kick                                 |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: PlayerName.....: flux
[ACEv14e]: PlayerIP.......: 50.72.94.161
[ACEv14e]: OS.............: Microsoft Windows 11 x86 (Version 10.0.26200)
[ACEv14e]: CPU............: AMD Ryzen 5 5600G with Radeon Graphics
[ACEv14e]: CPUSpeed.......: 3899.994385 Mhz
[ACEv14e]: NICDesc........: ASIX AX88179 USB 3.0 to Gigabit Ethernet Adapter
[ACEv14e]: MACHash1.......: 518EEE0C97E1A445C6850A85E8D3476C
[ACEv14e]: MACHash2.......: E085AB498AF48B05D8732EDF55C60E0F
[ACEv14e]: HWID...........: E88FC99B1509F66B00B6F16775E0AE50
[ACEv14e]: GameVersion....: 469e - Release / x86
[ACEv14e]: Renderer.......: D3D11Drv.D3D11RenderDevice
[ACEv14e]: SoundDevice....: ALAudio.ALAudioSubsystem
[ACEv14e]: CommandLine....:
[ACEv14e]: TimeStamp......: 01-08-2026 / 06:02:14
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                                 Kick Reasons                                 |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: KickReason.....: Illegal ProcessEvent Call Detected
[ACEv14e]: UFunction Name.: Nexgen112N.NexgenClient.hasRight
[ACEv14e]: Func Ptr.......: 6305E3E0
[ACEv14e]: Func Data......: Core.dll!?ProcessInternal@UObject@@QAEXAAUFFrame@@QAX@Z:0000
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                               Screenshot Status                              |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: Filename.......: ../Shots/[ACE] - FullMetalJacket Deathmatch (Ping Compensation - IG+)_2026.08.01.00.54.27_DM-Grinder_28_flux.jpg
[ACEv14e]: Status.........: Success
[ACEv14e]: +------------------------------------------------------------------------------+
```

## Kick log 2 — DaSnaksta (same second, same map)

```
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                                  Player Kick                                 |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: PlayerName.....: DaSnaksta
[ACEv14e]: PlayerIP.......: 65.94.86.48
[ACEv14e]: OS.............: Microsoft Windows 11 x86 (Version 10.0.26200)
[ACEv14e]: CPU............: AMD Ryzen 7 7800X3D 8-Core Processor
[ACEv14e]: CPUSpeed.......: 4192.044434 Mhz
[ACEv14e]: NICDesc........: Realtek Gaming 2.5GbE Family Controller
[ACEv14e]: MACHash1.......: DF61DFB4772FDEF1D36FA21A4E3777C7
[ACEv14e]: MACHash2.......: 49FCD612FA3851DC86AAB20AD3AE91FD
[ACEv14e]: HWID...........: E4BACA6DAA2CC03BF3198CCED60E7A1D
[ACEv14e]: GameVersion....: 469e - Release / x86
[ACEv14e]: Renderer.......: D3D11Drv.D3D11RenderDevice
[ACEv14e]: SoundDevice....: ALAudio.ALAudioSubsystem
[ACEv14e]: CommandLine....: -pktlag=0
[ACEv14e]: TimeStamp......: 01-08-2026 / 06:02:14
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                                 Kick Reasons                                 |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: KickReason.....: Illegal ProcessEvent Call Detected
[ACEv14e]: UFunction Name.: Nexgen112N.NexgenClient.hasRight
[ACEv14e]: Func Ptr.......: 6248E3E0
[ACEv14e]: Func Data......: Core.dll!?ProcessInternal@UObject@@QAEXAAUFFrame@@QAX@Z:0000
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: |                               Screenshot Status                              |
[ACEv14e]: +------------------------------------------------------------------------------+
[ACEv14e]: Filename.......: ../Shots/[ACE] - FullMetalJacket Deathmatch (Ping Compensation - IG+)_2026.08.01.00.54.27_DM-Grinder_27_DaSnaksta.jpg
[ACEv14e]: Status.........: Success
[ACEv14e]: +------------------------------------------------------------------------------+
```

## Source of the flagged function — `NexgenClient.hasRight` (Nexgen112N core, `NexgenClient.uc`)

Pulled from the `dscheerens/nexgen` archive (core Nexgen 1.12, same lineage as this server's 1.12N fork).
`hasRight` itself is a trivial local string check:

```unrealscript
simulated function bool hasRight(string rightID) {
	return instr(separator $ rights $ separator, separator $ rightID $ separator) >= 0;
}
```

It's called constantly by Nexgen's own built-in idle/AFK-kick system, inside `NexgenClient`'s per-client
idle tracking:

```unrealscript
} else if (!bSpectator && !hasRight(R_CanBeIdle) && level.pauser == "") {
    // ...decrements idleTimeRemaining every tick, eventually:
    // showPopup("NexgenIdleKickedDialog"); clientCommand(disconnectCommand);
```

Neither flux nor DaSnaksta has `R_CanBeIdle` (neither is an admin), so this runs on both of them every
tick, continuously, for the whole time they're connected — making `hasRight` the single most frequently
executing `simulated` (client-side) UnrealScript call in their client process. Working theory: ACE's
ProcessEvent hook-integrity check has some transient false-positive trigger unrelated to Nexgen, and
`hasRight` gets blamed disproportionately often purely because it's almost always the function that's
mid-flight when that trigger fires — which also explains why it hit two different players in the same
second (a shared, tick-level trigger would catch whatever's ticking for every connected client at once).

## What NexgenACEExt is and isn't expected to do here

NexgenACEExt bridges Nexgen and ACE (crosshair scaling fix + a clean hardware-info interface). It does
**not** touch `NexgenClient.hasRight` or Nexgen's idle-kick system at all - so installing it is not a
guaranteed fix for this specific false-positive. It's a plausible-but-unverified lead based on it being
the official interop layer between the two systems and this server currently running without it. Treat a
successful compile + install as an experiment to monitor, not a confirmed fix - the real test is whether
`Illegal ProcessEvent Call Detected` / `NexgenClient.hasRight` kicks stop recurring after it's live for a
while.
