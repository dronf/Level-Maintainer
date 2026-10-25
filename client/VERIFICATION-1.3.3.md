# NEI Level Maintainer 1.3.3 verification

Built 2026-10-24. JAR: nei-level-maintainer-1.3.3.jar

SHA-256: `9cc434301f4c4c5f107a1c8f5130f360ae88349f111a58af7ca4b9b3fdb48d20`

## Scope

Documentation, release packaging, a corrected settings comment and client version
metadata/build filename changed relative to merged 1.3.2. Crafting, polling,
keyboard, display and clipboard executable behavior are unchanged. This release
does not patch the reported multiplayer server-list networking exception.

## Build and binary compatibility

JDK 17 --release 8, Minecraft 1.7.10 production SRG merged JAR, Forge
10.13.4.1614, NEI 2.8.155-GTNH, OpenComputers 1.12.64-GTNH, and installed GTNH
2.9 RC2 dependencies. Pack contains lwjgl3ify 3.0.37. Verified all 16 Java 8
classes and 1,367 member references, SRG overrides, mod metadata and common
entrypoint loading with -Xverify:all. No dependency classes are bundled.

## Passed this release

- Java: 20 encoder, 38 reply parser, 74 text-field, 77 editor/button checks
  (80 with real lwjgl3ify), shared-buffer isolation, 12 pause/resume controls,
  23 batched/fallback listing lifecycle and 34 gameplay/NEI hotkey checks.
- Lua 5.2: maintenance, timed refills, pause (41 checks), idle polling,
  installer, settings merge, display, timestamps, receiver (23), manager (37),
  batched listing (29), and real extracted OpenOS buffered I/O (11).
- Node config-editor round trips, targets, legacy backups, invalid imports,
  plain-number output and paste chunks.
- Documentation relative paths/anchors and Lua code-block syntax checks.
- Release archive CRC, client metadata/Java version/namespace, user-config
  exclusion from OC bundle, complete staged-source inclusion and SHA-256 checks.

The deterministic 23-entry/300-second idle test retains the 30-to-1 stocked
CPU snapshot reduction, zero snapshots for empty/paused lists, and 30 snapshots
for an active maintained job. This measures API calls, not live server MSPT.

## Reproduce and limits

See [build/test instructions](../docs/DEVELOPMENT.md) and
[installation/acceptance checks](../docs/INSTALLATION.md). Java input tests use
real Minecraft classes with synthetic input; Lua tests simulate the OC/AE2
boundary. The optional Playwright full-browser suite and historical renderer
comparison were not rerun for this documentation release. Full modpack gameplay,
rendered hover help, actual network delivery and TPS require in-game checks.

The complete source archive contains repository source, tests, guides and the
release packaging tool. The OC bundle uses config.lua.example/settings.lua.example
and omits live user overrides. Dependency JARs remain external build inputs.
