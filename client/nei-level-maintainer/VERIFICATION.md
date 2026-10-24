# NEI Level Maintainer 1.3.0 verification - 2026-10-23

Artifact: `nei-level-maintainer-1.3.0.jar`.
SHA-256: `67a036d5215d210e70234ab949027fb0356c9be68bbec95e0b9991bf337d07f6`.

Built using JDK 17 with `--release 8` against the actual installed GTNH 2.9 RC2
Minecraft 1.7.10 SRG, Forge 10.13.4.1614, NEI 2.8.155-GTNH and OC 1.12.64-GTNH
binaries. All 16 classes use Java 8 format; all 1,330 member references resolve
against the pack dependencies. Metadata, entrypoints and SRG GUI overrides pass.
Only addon classes, manifest and mcmod.info are packaged; no dependencies are bundled.

## Listing benchmark

The real Lua receiver handles the same 23 representative item/fluid entries in
LM3 and LM4, using a deterministic GPU and no network delays. Counts exclude the
final cleanup command and any retries:

| Screen | Listing exchanges, old -> new | GPU set calls, old -> new | GPU fill calls, old -> new |
| --- | --- | --- | --- |
| 50x16 | 24 -> 2 | 58 -> 30 | 24 -> 0 |
| 80x25 | 24 -> 1 | 46 -> 18 | 24 -> 0 |
| 160x50 | 24 -> 1 | 24 -> 9 | 24 -> 0 |

Longer names/values require more pages. This measures transport/component work,
not a promised 12x/24x wall-clock speedup or a reduction in server MSPT. The exact
OC JAR's clipboard cooldown is message length divided by ten milliseconds;
short list requests incur only a few milliseconds. Serialized round trips,
GPU work and synchronization are the larger avoidable costs.

## Passed checks

- 29 Lua batch checks: frozen snapshots, idempotent first-page retry, external
  config edits, screen resizing, expiry, wrong-token cleanup, empty list,
  too-small screen, 64-record/4,096-character bounds, and GPU call counts.
- 104 Java protocol checks including LM2, LM3 and LM4 frames emitted by the real
  Lua receiver, Unicode/semicolon names, legacy empty quantities, pause flags,
  wrong offsets/nonces, malformed/partial records and checksum failures.
- 23 real ManagerGui tick/control checks with deterministic transport/time:
  multi-page loading, stale/partial replies, retries, atomic completion, retained
  selection, cancelled/failed load restrictions, empty results, legacy fallback,
  late replies, changed totals, timeout and close cleanup.
- Existing 12 manager pause checks, 20 update-encoder checks, 74 real text-field
  checks, 77 editor/render checks (80 with the installed lwjgl3ify buffer), and
  the shared-buffer input leak regression pass.
- Existing Lua maintenance, refill, pause (41), receiver (23), manager (38),
  real OpenOS buffered-I/O (11), display, settings, installer and utility suites
  pass. Display tests cover purple paused rows and header/log overlay protection.
- Renderer equivalence still passes all 20 previous layout/depth/page cases.
- JAR/ZIP CRCs, Java versions, artifact namespaces and companion package contents
  are checked. Companion scripts omit existing user configuration/overrides.

## Reproduce

Run the client README's build and verify scripts with the actual pack JARs.
From the repository root, run Lua 5.2+:

```sh
lua tests/nei-batch.lua batch-80.txt batch-50.txt
lua tests/nei-manager.lua frames.txt pause-frames.txt client/nei-level-maintainer/build/pause-commands.txt
lua tests/nei-bridge.lua
lua tests/maintenance.lua
lua tests/refill-interval.lua
lua tests/pause.lua
lua tests/display.lua
lua tests/settings.lua
lua tests/installer.lua
lua tests/utility.lua
```

Then use the emitted ASCII frames with the Java test:

```sh
java -cp "client/nei-level-maintainer/build/classes;client/nei-level-maintainer/build/tests" dev.dronf.neilevel.ScreenReplyTest frames.txt pause-frames.txt batch-80.txt batch-50.txt
```

The Lua manager test's last argument is optional and consumes commands generated
by ManagerPauseTest during the build. See the preceding verification document
for extraction/testing of the real OpenOS buffering implementation.

## Protocol

`LM4|Q|nonce|screen|offset` requests a page. Offset is the number of records
already received, beginning at zero. Replies are
`LM4R|nonce|offset|total|count|records|adler32|END`.
Records are separated with semicolons; each is the existing LM3 seven-field
item/fluid record with a hex UTF-8 name and pause flag. The initial response
already contains entries. The client advances by count and commits only when
the total is reached. Repeated offset-zero queries with the same nonce reuse
the snapshot until its five-second idle expiry. A new refresh uses a new nonce.
`LM2|END|nonce` releases the overlay for all versions.

Boundary: production UI/receiver/serializer/scheduler code is exercised, while
OC/AE2/GPU/network delivery is simulated. Fonts/drawing are stubbed in headless
GUI tests. Full modpack transformation and physical gameplay still need the
acceptance checks in INSTALLATION-1.3.0.md.
