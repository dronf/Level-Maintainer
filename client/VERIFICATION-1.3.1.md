# NEI Level Maintainer 1.3.1 verification - 2026-10-24

Artifact: `nei-level-maintainer-1.3.1.jar`.
SHA-256: `6694395e870ee24e7ee3d3248134ce8a8bc9249ba12b72c759144beb48371822`.

Built with JDK 17 `--release 8` against the actual installed GTNH 2.9 RC2
Minecraft 1.7.10 SRG, Forge 10.13.4.1614, NEI 2.8.155-GTNH and OC 1.12.64-GTNH
binaries. All 16 classes are Java 8 bytecode. The verifier resolved all 1,353
member references, checked metadata/SRG overrides and loaded entrypoints with
`-Xverify:all`. Only addon classes, manifest and mcmod.info are packaged.

## Passed checks

- 34 hotkey checks invoke the actual FML key/tick and NEI container callbacks
  with synthetic LWJGL event state. They cover both Ctrl keys, deferred opening,
  held/repeated/duplicate events, release-only and character-only events,
  unrelated keys, text-entry screens, no-world/no-player guards, changed
  screen/world/player cancellation and both Shift keys in the inventory path.
- Existing real Minecraft GUI checks: 74 field-focus/input, 77 editor/render
  checks (80 using installed lwjgl3ify 3.0.37), shared-buffer leak regression,
  12 pause/resume controls and 23 batched/fallback listing lifecycle checks.
- 20 command-encoder and 38 screen-reply protocol checks.
- JAR and source ZIP CRCs, namespaces, Java class version and release metadata.

The gameplay handler uses Forge 1.7.10's FML KeyInputEvent on the existing FML
bus registration. It only queues a manager in a loaded world with no screen
open. The NEI handler retains hovered-item editing and stale-editor input
forwarding. Both paths wait until M and both Ctrl keys are released, and open
at ClientTickEvent END after confirming the original screen/world still match.
No Lua, clipboard protocol, AE2 polling or CPU scheduling changes are included.

## Reproduce and limits

Run tools/build.ps1 and tools/verify.ps1 as documented in the client README,
passing the real pack dependencies. The build includes HotkeyTest alongside
the existing regression suite. The test uses actual Minecraft/LWJGL classes
but supplies keyboard state and replaces opening a rendered GUI with a recorder.
It does not simulate physical hardware, full modpack transformation or network
delivery. Perform the acceptance checks in INSTALLATION-1.3.1.md in Minecraft.

The prior Lua/transport benchmark and verification remain documented in
client/VERIFICATION-1.3.0.md; those components were not changed in this release.
