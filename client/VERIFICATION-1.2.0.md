# NEI Level Maintainer 1.2.0 verification

Built with JDK 17 `javac --release 8` against the actual GTNH 2.9 RC2 binaries.
Artifact: `nei-level-maintainer-1.2.0.jar`.
SHA-256: `7f3c76870b379f1235514e0683b171f2df12f42807645af6ee8dd2fad6057ed4`.

## Binary compatibility

All 16 addon classes use Java 8 class format 52. The bytecode verifier resolves
all 1,166 field/method references against actual Minecraft 1.7.10 SRG, Forge
10.13.4.1614, NEI 2.8.155-GTNH, OC 1.12.64-GTNH and the pack libraries, including
static/instance access. The JAR contains only addon classes, manifest and metadata.
Dependencies are not redistributed. No custom server handler or external service
is introduced; commands still use OC's existing clipboard transport and screen
responses use its normally synchronized text buffer.

## Passed tests

- 20 Java update-encoder checks; 41 reply/management checks when consuming real
  Lua-generated LM2 and LM3 GPU frames, including paused flags and Unicode.
- 12 checks exercising actual ManagerGui controls with transport recorded:
  selection, Pause/Resume labels, item/fluid commands, purple rows, disabled
  controls while syncing, explicit Remove, and refresh from authoritative state.
  Its emitted pause/resume commands are consumed by the Lua receiver tests.
- 74 real GuiTextField checks and 77 editor/render checks; 80 editor/render
  checks with the installed lwjgl3ify 3.0.37 shared input buffer. The dedicated
  shared-buffer leak regression also passes. Fonts/drawing are stubbed for these
  headless tests; Minecraft's storage, cursor, focus and insertion code is real.
- 38 Lua manager checks: LM2 compatibility, LM3 paused snapshots, pause/resume,
  restart persistence, legacy continuous entries, quantity/type edits preserving
  pause and fluid/refill metadata, tombstones, invalid flags, unknown entries,
  write/rename failures, expiry and corrupt-file protection.
- 41 real Maintainer/AE2-loop pause checks with deterministic components:
  items and fluids, immediate/completing jobs, no stock queries while paused,
  immediate dashboard status/color, resume of an active refill above Low,
  capped final batch, persistence and unchanged CPU query cadence.
- 23 existing PR #5 receiver checks and 11 checks with the unmodified OpenOS
  buffered I/O extracted from OC 1.12.64-GTNH, including paused saves and
  explicit flush/close failures.
- Existing maintenance, refill-interval, display, settings, installer and utility
  suites pass. The real display test verifies purple `0xCC88FF` and `paused` text.
- Rendering matches the pre-optimization renderer in 20 layout/depth/page cases.
  A 23-row draw uses 2 metadata queries instead of 8. Header cadence tests confirm
  maintenance and scheduled refill timing are unchanged. These component-call
  counts are not a measurement of server MSPT.
- ZIP CRCs, Java class versions, JAR metadata and package contents verified.

## Reproduce

Use the client README's PowerShell build/verify commands with your pack binaries.
From the repository root with Lua 5.2+:

```sh
lua tests/pause.lua
lua tests/maintenance.lua
lua tests/refill-interval.lua
lua tests/nei-bridge.lua
lua tests/nei-manager.lua frames.txt pause-frames.txt client/nei-level-maintainer/build/pause-commands.txt
lua tests/display.lua
lua tests/settings.lua
lua tests/installer.lua
lua tests/utility.lua
python tests/extract-openos.py /path/to/OpenComputers-1.12.64-GTNH.jar /tmp/openos-lib
lua tests/nei-openos-io.lua /tmp/openos-lib
```

Then run Java's ScreenReplyTest with the two emitted frame files. The optional
third Lua manager argument consumes commands emitted by ManagerPauseTest during
the client build. Omit that argument when running the Lua tests independently.

## Verification boundary

The production receiver, serializer, manager controls, parser and Maintainer
loop are tested; OC/AE2/GPU interactions are simulated. Full modpack mixin
transformation, physical keyboard input and real network/screen synchronization
have not been tested in a running Minecraft session. Follow the installation
document's in-game acceptance test for those paths.
