> Historical release record for the version named below. For current commands and behavior, use the [project guides](../README.md).

# NEI Level Maintainer 1.3.2 verification - 2026-10-24

Artifact: `nei-level-maintainer-1.3.2.jar`
SHA-256: `e44a0937105132545ee13c9e0c7b9d03ed4910f8b0581a882a19a58946655813`

Built against the actual installed GTNH 2.9 RC2 Minecraft 1.7.10 SRG, Forge
10.13.4.1614, NEI 2.8.155-GTNH and OpenComputers 1.12.64-GTNH binaries using
JDK 17 --release 8. All 16 classes use Java 8 bytecode. The verifier resolved
1,367 member references, checked production SRG overrides and mod metadata,
and loaded entrypoints with -Xverify:all. No dependency classes are bundled.

## Passed checks

- Client: 20 encoder, 38 reply parser, 74 field focus/input, 77 editor/button
  checks (80 with installed lwjgl3ify), shared-buffer isolation, 12 pause/resume,
  23 listing lifecycle and 34 hotkey lifecycle checks.
- Lua: maintenance, timed refills, pause/resume, idle polling, installer,
  settings merge, display, utility, clipboard bridge and manager, batched
  listing, and actual OpenOS buffered-I/O compatibility.
- A 23-entry, 300-second deterministic scheduler scenario with 10-second
  cycles and a 300-second stocked cooldown reduces getCpus from 30 to 1,
  and finalOutput calls for an unrelated busy CPU from 30 to 1. Fully paused
  and empty configurations make zero such calls. An active maintained job
  still produces 30 snapshots, preserving its prior observation cadence.
  Resume restores requests, and cached/unknown CPU headers are checked.
- The actual installer is tested with failure at each script backup and
  replacement position, failed fresh installation, invalid/truncated Lua,
  failed rollback with preserved backup, stale-backup refusal, successful
  cleanup, settings preservation, and optional version selection.
- ZIP/JAR CRCs, Java class versions, namespace and release metadata checked.

## Reproduce

Run client/nei-level-maintainer/tools/build.ps1 and tools/verify.ps1 with the
actual pack dependency paths as documented in the client README. From the
repository root, run Lua 5.2+:

```sh
lua tests/idle-polling.lua
lua tests/maintenance.lua
lua tests/refill-interval.lua
lua tests/pause.lua
lua tests/installer.lua
lua tests/settings.lua
lua tests/display.lua
lua tests/utility.lua
lua tests/nei-bridge.lua
lua tests/nei-manager.lua
lua tests/nei-batch.lua
lua tests/nei-openos-io.lua /path/to/extracted/OpenOS/lib
```

The automated harness uses the real scheduler and adapters with deterministic
OC component responses. It measures API calls, not TPS/mspt. Client checks use
real Minecraft/LWJGL classes with synthetic input and do not run a full game.
Tooltip rendering and real server behavior require the acceptance checks in
INSTALLATION-1.3.2.md. Rollback covers reported filesystem failures; sudden
power loss may require manually restoring the preserved backup files.
