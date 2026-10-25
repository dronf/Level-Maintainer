# Installation and updates

[Overview](../README.md) - [Usage](USAGE.md) - [Troubleshooting](TROUBLESHOOTING.md)

## Requirements

- GTNH 2.9 / Minecraft 1.7.10 with NEI and OpenComputers. Verified client
  dependencies: Forge 10.13.4.1614, NEI 2.8.155-GTNH, OC 1.12.64-GTNH.

The maintainer has **no hardcoded minimum case, CPU, RAM, GPU or screen tier**.
Choose compatible components that fit the case and can address the attached OC
component network. For the interactive dashboard and NEI manager:

| Component | Requirement |
| --- | --- |
| Case and CPU | A working OC computer; no particular tier is enforced by the script |
| RAM | Enough memory for OpenOS, the program, maintained entries and listing snapshots; larger lists need more memory |
| Hard drive | OpenOS plus the installed scripts and configuration files |
| EEPROM | A Lua BIOS EEPROM to boot OpenOS |
| GPU and screen | Needed for the dashboard and the NEI manager's screen replies; no fixed tier, with pagination on smaller displays |
| Keyboard | Attached for normal interactive OC use and the existing clipboard path |
| Adapter | Connected to the computer's OC network and touching a full-block ME interface |
| Internet card | Installation and updates only; removable during ordinary maintenance |
| Redstone card | Optional; only needed for the wake-on-redstone feature |

Install OpenOS by booting its floppy, running `install`, selecting the hard
drive, rebooting and removing the floppy. Provide normal OC power and a powered
AE2 network with crafting patterns, suitable crafting CPUs, ingredients and
processing machines. Install Crafting Monitors on CPUs for reporting active
outputs through OC. The Java addon remains client-only; none of this requires
installing it on the server.

No exact minimum RAM capacity has been established for every list size. A lack
of tier checks does not guarantee that the smallest possible build fits every
workload. More RAM is useful for larger lists; higher GPU **and screen** capability
provides more display space. A T3 GPU is sufficient for the graphics tier, but
the screen can still limit the available resolution.

The default `fit` layout deliberately selects large text according to row count.
This is not evidence that a T3 GPU failed. Use `fixed` or `columns` to retain
the screen resolution; overflowing rows are paginated. See [display controls](USAGE.md#dashboard).

Faster OC hardware does not speed up AE2 crafting recipes. Recipe duration is
determined by the processing machines, while script settings such as `sleep`
and `refillInterval` determine when maintenance checks are due. OC execution
and AE2 calculation time can add delays; a hardware upgrade does not change
the configured intervals or the machines' processing rate.

Keep your GTNH instance's supported Java/runtime setup. Java 8 output bytecode
does not mean you should downgrade a modern GTNH launcher.

## Install the release scripts

Use one OC directory, normally /home, for the program and its data. Run:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/nei-level-maintainer-1.3.3/installer.lua installer.lua
installer nei-level-maintainer-1.3.3
```

The installer selects the tag's commit to download one matching script set. It
installs Maintainer.lua, nei_bridge.lua and four src/ modules. Missing config.lua
and settings.lua are fetched; existing files are retained. Review the fresh
config.lua's example entries and replace them with your own craftable labels.

If settings explanations/defaults changed, it offers to refresh settings.lua
while preserving values and saving settings.lua.old. Declining preserves the
file; missing options use built-in defaults. Invalid settings are not silently
overwritten. It can also offer auto-start and wake-on-redstone. A successful
installation reboots OC.

Run `Maintainer` from its installation directory if auto-start is off. Stop with
**Q** or **Ctrl+Alt+C**. Jobs already submitted to AE2 continue.

## Install the client JAR in Prism

1. Download `nei-level-maintainer-1.3.3.jar` from the
   [release](https://github.com/dronf/Level-Maintainer/releases/tag/nei-level-maintainer-1.3.3).
2. Close Minecraft. Select the Prism instance and open its Minecraft folder.
3. Replace the previous NEI Level Maintainer addon in `.minecraft/mods`.
   Keep exactly one addon version, plus the normal NEI/OC dependencies.
4. Relaunch and join the world. This addon goes on the client only.

The OC ZIP is a script bundle, not a mod; do not put it in mods. Examples use
config.lua.example and settings.lua.example so extraction does not replace your
existing configuration. Check downloads against the release's SHA256SUMS file:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath 'C:/Downloads/nei-level-maintainer-1.3.3.jar'
```

## Screen UUID

Stop Maintainer, run `lua` to enter the interpreter, and enter:

```lua
for address in require("component").list("screen") do print(address) end
```

With several screens, find the active GPU's binding:

```lua
print(require("component").gpu.getScreen())
```

Press Ctrl+D to exit Lua and run Maintainer again. Use this screen UUID in the
addon, not the computer/GPU/keyboard address. Keep its keyboard attached.
Open the OC screen normally once to synchronize its client buffer, then close
it and use Ctrl+M. Stand within normal OC interaction range and permissions.

## Update later

Stop Maintainer first. Back up config.lua, settings.lua and nei_overrides.lua.
The last file stores NEI changes, removals and pause states; config.lua alone
does not describe the effective configuration.

For the exact release use the tagged commands above. For current merged master:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The optional installer argument accepts a branch, tag or commit; omission means
master. Download the installer from the same ref when testing an unmerged build.
Restart OC after updates to refresh cached modules/listeners.

1.3.3 has the same runtime behavior as 1.3.2, with updated documentation/version
metadata. Existing 1.3.2 scripts already provide those runtime improvements.

## Failed update recovery

Downloads are staged and compiled as Lua without executing them. Invalid or failed
downloads leave the installed scripts untouched. Originals are moved to
.install-backup paths until every script replacement succeeds. A reported
replacement failure triggers rollback and stops without rebooting. If rollback
also fails, the remaining backup paths are printed and preserved.

After power loss or failed rollback, keep the backups and prevent auto-start
while recovering. Inspect each reported file and restore its original to the
corresponding filename before retrying. The installer refuses to overwrite a
leftover recovery backup. settings.lua.old and nei_overrides.lua.bak are separate
settings/override backups; do not confuse them with script backups.

## Auto-start and power-loss recovery

Auto-start adds a line to /home/.shrc using the installation directory:

```sh
cd "/home" && Maintainer
```

Remove it to disable auto-start. A redstone card can use wake threshold 1 so a
rising redstone signal boots an off computer; use a slow clock if desired.
This does not supply OC power or repair a broken config. Avoid duplicate startup lines.

Complete the [in-game acceptance checklist](DEVELOPMENT.md#in-game-acceptance-checklist)
after installing.
