> Historical release record for the version named below. For current commands and behavior, use the [project guides](../README.md).

# NEI Level Maintainer 1.2.0

Pause and resume individual items or fluids from **Manage existing entries**.
Update both the client JAR and the OpenComputers scripts for this feature.
Minecraft 1.7.10 / GTNH 2.9, NEI 2.8.155-GTNH, OC 1.12.64-GTNH.

## Install the client

1. Close Minecraft in Prism Launcher.
2. Open the GTNH instance's Minecraft folder, then `mods`.
3. Remove the previous `nei-level-maintainer-*.jar` and put
   `nei-level-maintainer-1.2.0.jar` there. Keep exactly one version.
4. Restart Minecraft. Install the addon on your client only.

## Update OpenComputers

After the pause-feature PR is merged, press Q to stop Maintainer, change to its
installation directory (usually `/home`), and run:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The installer downloads matching versions of Maintainer, `nei_bridge.lua` and
the `src/` helpers. It keeps existing `config.lua` and `nei_overrides.lua`.
If it offers a settings refresh, your existing values are preserved and the
previous settings file is backed up. Let it reboot to clear cached Lua modules.

Before the PR is merged, use `level-maintainer-oc-1.2.0.zip`: stop Maintainer,
copy its contents into the OC installation directory, retaining the `src/`
folder, then reboot OC. That archive contains no `config.lua`, `settings.lua`
or `nei_overrides.lua`, so it does not replace your entries or settings.
For a remote server, use the installer after merging; the ZIP is useful when
you already have access to the OC drive files.

Do not use the master installer before merging and expect the pause feature:
it installs master even when installer.lua itself was downloaded from a branch.

## Pause and resume

1. Leave Maintainer running. Open its OC screen once, then close it.
2. In an inventory/NEI screen press **Left Ctrl+Shift+M**, or use **Left Ctrl+M**
   on an item and click **Manage existing entries**.
3. Enter the active GPU's screen UUID and click **Refresh** if needed.
4. Select an entry and click **Pause**. Wait for the refreshed list.
5. It stays in the manager with a purple **[Paused]** prefix and shows
   **paused** in purple on the OC dashboard (color depends on GPU depth).
6. Select it again and click **Resume** to enable maintenance.

Pause prevents new requests and stock checks for that entry. A craft already
submitted to AE2 continues to completion. The last known stock value can remain
on screen while paused. Other entries continue normally; nothing is removed.
Pause is saved in `nei_overrides.lua` and survives OC/server restarts. Amount
edits and Item/Fluid conversions preserve it, along with refill timing and fluid
identity. Resume retains Low, Target and Batch. During the same process an active
refill continues toward Target at the next normal maintenance cycle; after an
OC process restart, refill activation follows the existing below-Low rule.

To configure pause by hand, add `paused = true` to the entry table. An NEI
override takes precedence over the matching entry in config.lua.

## Test in game

Use an inexpensive craftable item below its Low value. Pause it, verify the
purple status, let any existing job finish, and confirm no replacement is
requested. Resume it and confirm production returns at the next maintenance
cycle (subject to free CPUs and ingredients). Repeat with a fluid and restart
OC while paused to check persistence. Editing its amounts must keep it paused.
Remove remains a separate action with its existing confirmation.

Also check top-row/keypad numbers, Backspace/Delete and Tab in Add/Edit, then
return to NEI and confirm its search text has not changed. This release includes
the previous 1.1.5 keyboard fixes and Lua timestamp/display optimizations.
`headerInterval` defaults to 5 seconds; set it to 1 for smoother cosmetic updates.
The CPU polling rollback remains in place. Pause adds no extra CPU polling.

Compilation, API linkage, GUI-control, protocol and simulated maintenance tests
passed; physical in-game keyboard, network/screen synchronization and live AE2
crafting still need the acceptance test above. See VERIFICATION-1.2.0.md.
