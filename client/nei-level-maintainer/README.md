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

## Open and use the manager

- **Left Ctrl+Shift+M** from an inventory or NEI container opens the manager.
- **Left Ctrl+M** while hovering an item opens its Add/Edit/Remove editor.
  The editor's **Manage existing entries** button opens the manager.
- Left Ctrl+M without a hovered item also opens the manager.
- Enter the OC screen UUID and click **Refresh**. A saved UUID is reused and
  refresh starts automatically when opening the manager.
- Filter the loaded list by name; use Prev/Next to page. Click a row to select
  it, then **Edit**, **Pause/Resume** or **Remove**. Remove requires a second **Confirm?** click.
- **Add** opens an editor where you can enter an exact display name and choose
  Item or Fluid. Hovering an NEI item prefills its name. Set Low, Target and Batch
  and click Save to OC. Existing names are fixed; the Item/Fluid button can change type.
- After saving, return to the manager; it refreshes the actual OC state. An
  editor submission alone is not a server acknowledgement. Confirm Updated or
  Removed on OC, or refresh and check the entry in the manager.

Remove stops maintaining the entry even if it came from `config.lua`. It stores
`["name"]=false` in the appropriate override section, masking the base entry
without rewriting your config file. The deletion survives restart. Adding the
same name and type again replaces that marker and re-enables maintenance.
Keep the updated OC scripts while deletion markers exist; older receivers do
not understand them.
To restore the original base configuration instead, stop Maintainer and remove
that false marker from `nei_overrides.lua`, then restart.

Editing quantities preserves an existing entry's native `fluidName` and
`refillInterval`. Legacy configs with no Target are listed as `legacy`; the
editor requires you to choose an explicit Target when converting them to
Low/Target mode. Re-adding a removed entry creates a new explicit override.

## Screen UUID and sync requirements

To get the screen UUID, stop Maintainer, run `lua`, then enter:

```lua
for a in require("component").list("screen") do print(a) end
```

Press Ctrl+D to exit Lua and run `Maintainer` again. Use the screen address,
not the computer/GPU/keyboard address. Keep its keyboard attached. Open the OC
screen normally once so the client has its buffer, then close it and use NEI.
Stand close enough to use that screen normally, with normal OC permissions.

The listing request uses OC's existing clipboard path. Its response is ASCII
text briefly drawn on the GPU's bound screen and read from OC's existing client
screen buffer. During sync the dashboard briefly shows protocol text. Normal
display returns when sync finishes or the session expires (five seconds after
the last request, on the next dashboard redraw). Maintenance keeps running.
The entered screen must be the one bound to the computer's active GPU.

Replies are paginated, nonce-matched and protected with an Adler-32 checksum so
stale or partially synchronized screen data is not accepted as configuration.
A frozen snapshot keeps pagination consistent. One client can sync with a
computer at a time. Use Refresh again if another user or update interrupted it.

If sync times out, confirm updated scripts are loaded, Maintainer is running,
the screen address and GPU binding match, and you have opened the OC screen
once. Old receivers support updates but cannot list or remove entries. Avoid
editing until the manager says it loaded the entries from OC.

## Limits

Names match display names, not registry IDs or NBT; identical display names
collide. Names must be 1-160 UTF-8 bytes, without pipes or control characters.
The manager omits unsupported names and malformed non-table config entries.
It lists items and fluids; adding a fluid requires its exact configured display
name. The ME setup must support the corresponding craftable item/fluid.

New quantities are integers from 0 to 10^12, Low <= Target and Batch >= 1.
The manager reads current quantities; the hover editor initially uses saved
local defaults. Use the manager's Edit action to prefill an existing entry's
current values. The list supports up to 10,000 entries; synchronization of large
lists takes time. Exceptionally small screen resolutions may not fit a response.
Keyboard navigation, Ctrl+V, Tab and Shift+Tab are available in the entry editor.
Cancel closes the editor without submitting; containers are closed normally.

## Gameplay acceptance test

1. With Maintainer running, open Ctrl+Shift+M and Refresh. Verify entries from
   config.lua and previous NEI overrides appear, including a fluid if configured.
2. Edit an inexpensive craftable item's Low/Target/Batch. Refresh and verify the
   new values. Confirm its existing refill timing is retained.
3. Remove it, confirm, and verify it disappears from both the manager's refreshed
   list and the OC dashboard. Restart OC and verify it remains removed, including
   when it originally came from config.lua.
4. Add it again from NEI and verify it returns and ordinary crafting resumes.
5. Test Filter, Prev/Next, Cancel, invalid numbers, and a wrong screen UUID.

## Build and verification

See VERIFICATION.md. Automated compilation, binary API checks, Java/Lua protocol
tests and real Maintainer main-loop tests have passed. This new GUI/screen-sync
version has not been gameplay-tested in Minecraft.

Build using PowerShell, JDK 17 (emitting Java 8 bytecode), your exact pack JARs,
Prism's library directory and a Minecraft 1.7.10 SRG merged JAR from a
RetroFuturaGradle workspace (`build/rfg/srg_merged_minecraft.jar`). Dependency
JARs are not redistributed. Source uses production SRG names directly.

```powershell
./tools/build.ps1 -MinecraftSrgJar '<SRG Minecraft.jar>' `
  -ForgeJar '<Forge universal.jar>' -ModsDirectory '<instance>/.minecraft/mods' `
  -LibrariesDirectory '<Prism>/libraries' -JdkDirectory '<JDK 17>' `
  -OutputDirectory '<output directory>'
./tools/verify.ps1 -Jar '<compiled.jar>' -MinecraftSrgJar '<SRG Minecraft.jar>' `
  -ForgeJar '<Forge universal.jar>' -ModsDirectory '<instance>/.minecraft/mods' `
  -LibrariesDirectory '<Prism>/libraries' -AsmJar '<asm-9.8.jar>' `
  -JdkDirectory '<JDK 17>'
```

Lua tests run from the Level-Maintainer repository root using Lua 5.2+:

```sh
lua tests/nei-manager.lua frames.txt
lua tests/nei-bridge.lua
lua tests/maintenance.lua
lua tests/refill-interval.lua
lua tests/installer.lua
lua tests/settings.lua
lua tests/display.lua
```

The first command can emit real simulated GPU frames for Java's ScreenReplyTest:

```sh
java -cp "build/classes;build/tests" dev.dronf.neilevel.ScreenReplyTest frames.txt
```
