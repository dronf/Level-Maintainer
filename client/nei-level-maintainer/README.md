# NEI Level Maintainer 1.3.1

Ctrl+M now opens Manage existing entries during normal gameplay, without opening
an inventory or NEI first. Either left or right Ctrl works.

| Context | Shortcut | Result |
| --- | --- | --- |
| Normal gameplay | Ctrl+M | Manage existing entries |
| Inventory/NEI, hovering an item | Ctrl+M | Add/Edit that item |
| Inventory/NEI, no hovered item | Ctrl+M | Manage existing entries |
| Inventory/NEI, with or without a hovered item | Ctrl+Shift+M | Manage existing entries |

Release M and Ctrl to open the screen. Held/repeated shortcut events open it
once. Chat, OC terminals and other text-entry screens keep their own keys; close
those screens first. Changing screens/worlds before release cancels the open.

## Install/update

1. Close Minecraft. In Prism, open the GTNH instance's Minecraft folder, then
   `mods`. Replace the previous addon JAR with `nei-level-maintainer-1.3.1.jar`.
   Keep exactly one NEI Level Maintainer addon version.
2. Start Minecraft and join your world. Press and release Ctrl+M to open the
   manager. It reuses the saved OC screen UUID and starts refreshing when set.

This is a client-only update. Existing 1.3.0 OC scripts need no update for the
hotkey. The batched listing, Pause/Resume and previous input fixes are included.
The 1.2.0 receiver still works through the slower listing fallback. If upgrading
older scripts for the faster listing, stop Maintainer with Q and run this from
its OC installation directory, then let the installer reboot:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

Keep Maintainer running and open its OC screen once before syncing, so the
client has the screen buffer. Use the GPU-bound screen UUID and stand within
normal OC interaction range. No server addon or external service is required.

## Test in Minecraft

- In the world, use each Ctrl key with M. Hold the shortcut briefly, then release
  it; one manager should open, without stray text. Close it and repeat.
- In an inventory/NEI, Ctrl+M over an item should open its editor; Ctrl+Shift+M
  should open the manager. Ctrl+M over empty space also opens the manager.
- In chat or an OC terminal, Ctrl+M should retain that screen's normal behavior.
- Check that Add/Edit numbers accept top-row digits, numpad, Backspace, Delete
  and selection replacement, without changing the NEI search field.
- Refresh, edit and pause/resume an existing entry; verify the OC dashboard
  matches. Listing and transport behavior are unchanged from 1.3.0.

Automated hotkey, input, manager and binary API checks passed. Physical gameplay
has not been tested for this build; see VERIFICATION-1.3.1.md.

## Open and use the manager

- **Ctrl+M** during normal gameplay opens the manager. Either Ctrl key works.
- **Ctrl+Shift+M** from an inventory or NEI container opens the manager.
- **Ctrl+M** while hovering an item opens its Add/Edit/Remove editor.
  The editor's **Manage existing entries** button opens the manager.
- Ctrl+M without a hovered item also opens the manager.
- Enter the OC screen UUID and click **Refresh**. A saved UUID is reused and
  refresh starts automatically when opening the manager.
- Filter the loaded list by name; use the mouse wheel or Prev/Next to page. Click a row to select
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
once. The 1.2.0 receiver supports the slower fallback listing; update OC for batched replies. Avoid
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
