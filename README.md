# NEI Level Maintainer

Maintain AE2 item and fluid stock in **GT New Horizons 2.9**, using an
OpenComputers program and an optional client-only NEI addon. Add, edit, pause,
resume, and remove entries from Minecraft without editing Lua by hand.

**Current package: 1.3.4.** Fresh installs and runtime fallbacks now favor low
server load: slow polling, long retry/cache intervals, and an empty maintained
list. Existing saved settings remain preserved during updates.

[Download release](https://github.com/dronf/Level-Maintainer/releases/tag/nei-level-maintainer-1.3.4)
- [Client JAR](https://github.com/dronf/Level-Maintainer/releases/download/nei-level-maintainer-1.3.4/nei-level-maintainer-1.3.4.jar)
- [Changelog](CHANGELOG.md)

## OpenComputers hardware

The script does not enforce a particular case, CPU, RAM or GPU tier. For the
interactive dashboard and NEI manager, use a case with CPU, enough RAM, a hard
drive containing OpenOS, a Lua BIOS EEPROM, GPU, screen and keyboard. Connect
an OC adapter touching a full-block ME interface on the powered AE2 network.

An internet card is needed only for installation/updates and can be removed
afterward. A redstone card is optional, for wake-on-redstone. AE2 also needs
crafting patterns and usable crafting CPUs with Crafting Monitors for reporting
active outputs. See the [complete component table](docs/INSTALLATION.md#requirements).

More RAM helps larger maintained lists. Higher-tier GPUs and screens provide
more display space; smaller displays use pagination. The default fit layout
intentionally uses large text, even with a T3 GPU. Faster OC hardware does not
speed up AE2 recipes; processing machines and maintenance timing remain separate.

## Quick start

**The default polling frequency is deliberately very low to minimize server
load. Ordinary maintenance runs once per minute, and stocked-item checks are
spaced 5-60 minutes apart. Replenishment can therefore be slow; lower the timing
intervals in settings.lua if you need a faster response.**

1. Install OpenOS on an OC computer. Connect an adapter to a full-block ME
   interface on your powered AE2 network, with crafting patterns and CPUs.
2. Run these commands from your OC installation directory, normally /home:

   ```sh
   wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/nei-level-maintainer-1.3.4/installer.lua installer.lua
   installer nei-level-maintainer-1.3.4
   ```

3. Close Minecraft. Replace the previous addon in the Prism instance's
   `.minecraft/mods` with `nei-level-maintainer-1.3.4.jar`. Keep exactly one
   addon version. Install it on the client; the server uses its normal GTNH mods.
4. Run `Maintainer` on OC and open its screen once. **Ctrl+M** during normal
   gameplay opens the manager. Over an NEI item it opens that item's editor;
   **Ctrl+Shift+M** opens the manager. Either Ctrl key works; release the shortcut.
5. Enter the active GPU's screen UUID and Refresh. The manager loads the actual
   computer configuration. Select an entry to Edit, Pause/Resume, or Remove.

Keep the computer running and stay within normal OC interaction range. The
addon uses OC's existing clipboard packets and synchronized screen text. No
server addon or external service is required. An internet card is needed for
downloads, not ordinary maintenance.

## Documentation

| Guide | Contents |
| --- | --- |
| [Installation and updates](docs/INSTALLATION.md) | Hardware, OpenOS, Prism, screen UUID, pinned/master updates, backups and recovery |
| [Using the manager and dashboard](docs/USAGE.md) | Shortcuts, add/edit/remove, persistent pause, search, paging and status display |
| [Configuration reference](docs/CONFIGURATION.md) | Low/Target/Batch, continuous production, items/fluids and every setting |
| [Browser editor walkthrough](docs/BROWSER-EDITOR.md) | Worked example, lists, output modes, OC paste chunks, imports/backups, sharing and override conflicts |
| [Performance](docs/PERFORMANCE.md) | Server-load tuning, measured API calls, listing speed and polling tradeoffs |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Input, save/sync errors, missing patterns, stale stock, CPUs and crash reports |
| [Development and validation](docs/DEVELOPMENT.md) | Production build, real dependency verification, tests and release packaging |
| [Clipboard protocol](docs/PROTOCOL.md) | Request formats, screen replies, compatibility and limits |
| [Release history](CHANGELOG.md) | Changes by version and historical verification records |

## Low, Target and Batch

For **Low 10 / Target 64 / Batch 16**, production starts when observed stock is
**below 10**, continues in batches of up to 16 until stock reaches 64, then waits
until stock falls below 10 again. At exactly 10 an idle entry does not start.
The last request is capped by the missing amount; recipe output sizes can overshoot.
Items use individual units. Native fluids use mB: 1,000 mB = one bucket.

The Lua configuration also supports legacy thresholds and continuous production.
The NEI editor requires explicit Low, Target and Batch values. Read the
[configuration reference](docs/CONFIGURATION.md) before setting Low to zero.

## Compatibility and verification

Built against Minecraft 1.7.10, Forge 10.13.4.1614, NEI 2.8.155-GTNH and
OpenComputers 1.12.64-GTNH from GTNH 2.9 RC2, emitting Java 8 bytecode. This
does not establish compatibility with every older pack or other modpack.

Clients 1.3.4, 1.3.3 and 1.3.2 use the same protocol. Updated Lua also works with client
1.3.1; numeric hover help requires 1.3.2+. Client 1.3.0+ supports batched listing;
the slower 1.2.0 receiver fallback remains. Update both sides from older packages.

Automated tests exercise the real Lua scheduler with simulated OC/AE2 responses,
real Minecraft text fields with synthetic input, and binary API compatibility.
API-call measurements are not live TPS benchmarks. The release includes
verification results and an in-game acceptance checklist.

## Credits and browser editor

Fork of [Echoloquate/Level-Maintainer](https://github.com/Echoloquate/Level-Maintainer).
The offline [browser configuration editor](docs/index.html) is adapted from
[Willshaper's editor](https://github.com/Willshaper/Level-Maintainer/tree/ba32287d00dabf15ca6f96756d7cf9f0bc2c10d6/docs).
Download the repository and keep `docs/index.html` and `docs/config.js` together
to run it locally. Hosting is optional.
