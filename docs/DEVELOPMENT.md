# Development and validation

[Overview](../README.md) - [Protocol](PROTOCOL.md) - [Release history](../CHANGELOG.md)

## Layout

- Maintainer.lua: scheduling, reloads, state, CPU snapshots and dashboard rows.
- src/AE2.lua: targeted stock/craftable access and normal AE2 request submission.
- src/Display.lua and src/Utility.lua: guarded display and cached real-clock logging.
- src/Settings.lua: preserving values while refreshing settings explanations.
- nei_bridge.lua: clipboard receiver, override persistence and listing replies.
- installer.lua: matching-ref downloads, validation, replacement and rollback.
- client/nei-level-maintainer: client Java sources, build/verifier tools and tests.
- docs/index.html and docs/config.js: offline browser config editor.
- tests/: Lua and browser/config-editor regression suites.

Use production SRG Minecraft members. The client has no custom server channel.
Maintain old LM1/LM2/LM3 behavior when extending the LM4 listing path. Check that
input changes do not forward text to NEI or duplicate lwjgl3ify characters.

## Build the client JAR

Required: PowerShell, JDK 17 (Java 8 output), exact pack dependencies, Prism
libraries including the tested LWJGL 2 Windows natives, and a Minecraft 1.7.10
SRG merged JAR from a RetroFuturaGradle workspace:
build/rfg/srg_merged_minecraft.jar. Dependency JARs are not redistributed.

From client/nei-level-maintainer:

```powershell
$deps = @{
  MinecraftSrgJar = 'C:/build/rfg/srg_merged_minecraft.jar'
  ForgeJar = 'C:/Prism/libraries/net/minecraftforge/forge/1.7.10-10.13.4.1614-1.7.10/forge-1.7.10-10.13.4.1614-1.7.10-universal.jar'
  ModsDirectory = 'C:/Prism/instances/GTNH/.minecraft/mods'
  LibrariesDirectory = 'C:/Prism/libraries'
  JdkDirectory = 'C:/Program Files/Java/jdk-17'
}
./tools/build.ps1 @deps -OutputDirectory 'C:/build/release'
./tools/verify.ps1 @deps -Jar 'C:/build/release/nei-level-maintainer-1.3.3.jar' -AsmJar 'C:/build/asm-9.8.jar'
```

Replace example paths with your actual installation. build.ps1 currently expects
NotEnoughItems-2.8.155-GTNH.jar and OpenComputers-1.12.64-GTNH.jar. It compiles
with --release 8, runs Java protocol/input/manager/hotkey regressions, and packages
only addon classes plus metadata. When installed lwjgl3ify-3.0.37.jar is present,
it also checks that integration's real shared text buffer.

verify.ps1 resolves bytecode references against real Minecraft, Forge, pack mods
and libraries, checks Java class versions, metadata and SRG overrides, and loads
entrypoints with -Xverify:all. A successful build is not full gameplay validation.

## Lua and browser tests

From the repository root, use Lua 5.2 or later:

```sh
lua tests/maintenance.lua
lua tests/refill-interval.lua
lua tests/pause.lua
lua tests/idle-polling.lua
lua tests/installer.lua
lua tests/settings.lua
lua tests/display.lua
lua tests/utility.lua
lua tests/nei-bridge.lua
lua tests/nei-manager.lua
lua tests/nei-batch.lua
node tests/config-editor.cjs
```

These run actual modules/scheduler with deterministic component responses.
Installer tests inject download, backup, replacement and recovery failures.
An optional exact renderer comparison uses pre-optimization Display.lua from
commit 52208f2: lua tests/display-equivalence.lua /path/to/old-Display.lua.

Extract the actual OpenOS buffering implementation and run the compatibility test:

```sh
python tests/extract-openos.py /path/to/OpenComputers-1.12.64-GTNH.jar /tmp/openos-lib
lua tests/nei-openos-io.lua /tmp/openos-lib
```

Java/Lua cross-language frame validation, after the Java build:

```sh
lua tests/nei-manager.lua frames.txt pause-frames.txt client/nei-level-maintainer/build/pause-commands.txt
lua tests/nei-batch.lua batch-80.txt batch-50.txt
java -cp "client/nei-level-maintainer/build/classes;client/nei-level-maintainer/build/tests" dev.dronf.neilevel.ScreenReplyTest frames.txt pause-frames.txt batch-80.txt batch-50.txt
```

On Unix replace the classpath separator with a colon. Optional browser integration
tests need Playwright and Chromium: node tests/browser-editor.cjs. Set
PLAYWRIGHT_CHANNEL=chrome to use installed Chrome. They cover persistence,
backups, share links, atomic imports and mobile layout. They are distinct from
the lightweight Node config-editor suite.

## In-game acceptance checklist

1. Keep one addon JAR. Launch, join, open OC normally once and verify the bound UUID.
2. Test both Ctrl keys with M in gameplay. Hold/release: one manager opens.
   Test NEI hover Ctrl+M, Ctrl+Shift+M, and empty-space Ctrl+M.
3. Confirm chat/OC terminal input keeps its normal behavior.
4. In creation and manager editing, test top-row digits, numpad, Backspace/Delete,
   selection replacement, paste, Tab/Shift+Tab and Item/Fluid switching.
   No digits should leak into NEI search. Hover Low/Target/Batch for help.
5. Refresh actual entries, including a fluid. Test search, paging, cancel, wrong
   UUID and missing receiver. Only a complete list should become editable.
6. Add/edit an inexpensive craftable; verify OC acknowledgement and refreshed
   values. Pause/resume and remove/re-add; restart OC to verify persistence.
7. Verify Low/Target hysteresis, capped final request and a configured timed refill.
   Observe cached CPU/stock labels and an entirely paused list.
8. Check rollback in a disposable test computer, never by deliberately filling
   or corrupting the only production disk.
9. Compare server MSPT with similar jobs before/after if claiming performance.
   Automated API-call counts cannot establish a particular TPS improvement.

## Releasing

Keep the Java annotation, mcmod.info and build output filename aligned. Run
the real dependency build/verifier and relevant Lua/browser tests. Record the
exact dependencies, result counts and limits in the current verification note.

Use tools/package-release.py with the verified JAR and output directory. It
includes the full source tree without .git/build artifacts, a separate OC bundle
without active user config filenames, release docs and SHA-256 checksums.
Publish those assets to the same immutable version tag referenced by installer
commands. Re-download the published JAR and compare its digest, confirm the
tagged installer matches the intended commit, and check release asset names.
The normal master update command only includes changes after they merge.
