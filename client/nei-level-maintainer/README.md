# NEI Level Maintainer 1.3.0

Manage existing entries now loads a batch of entries per clipboard/screen exchange.
In the 23-entry test, listing exchanges drop from 24 to 1 on an 80x25 or 160x50
screen, and to 2 on a 50x16 screen. These are measured protocol counts; elapsed
time in game still depends on server ticks, OC execution and screen synchronization.

The manager also retains the selected entry after refresh, supports mouse-wheel
paging, remembers a successfully used screen UUID and shows the completed load
time. Refresh becomes Cancel while loading. Closing or cancelling sends an END
request so the dashboard can return promptly; OC's existing clipboard cooldown
can defer cleanup to the session timeout. A failed or cancelled refresh leaves
the previous list visible with Edit/Pause/Remove disabled until a fresh load.

## Install/update

1. Close Minecraft. In Prism, open the GTNH instance's Minecraft folder and its
   `mods` folder. Replace the old NEI Level Maintainer addon with
   `nei-level-maintainer-1.3.0.jar`; keep exactly one addon version.
2. After the batched-manager PR is merged, press Q to stop Maintainer and run
   this from its OC installation directory (usually `/home`):

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

3. Let the installer reboot OC to clear cached Lua modules. Existing config,
   NEI overrides and settings values are preserved. Restart Minecraft with the
   new client JAR.

Update both the JAR and OC scripts to get the faster listing. With the 1.2.0
receiver, the new client waits 1.5 seconds then falls back to the older per-entry
listing and suggests updating OC. Updated scripts retain LM1/LM2/LM3 support for
older clients. Pause/Resume and the earlier keyboard fixes are included.

Before merging, `level-maintainer-oc-1.3.0.zip` can be copied into an accessible OC
drive's installation folder with Maintainer stopped, retaining its `src/` folder.
Then reboot OC. The ZIP contains no config.lua, settings.lua or nei_overrides.lua.
The normal master installer installs this change only after the PR is merged.

## Use and test

Open an inventory/NEI screen and press Left Ctrl+Shift+M, or use the entry editor's
Manage existing entries button. Keep Maintainer running and open its OC screen
once before syncing. The screen must be bound to that computer's GPU.

- Refresh a list containing both items and fluids. Check the total, names,
  amounts and paused flags against OC. Record the displayed load time.
- Select an entry and pause/resume or edit it. The refreshed selection should
  remain on that entry, and the OC status should agree.
- Use Filter, mouse-wheel paging and Prev/Next. Cancel a refresh and refresh
  again; partial data must not become editable. Close during a refresh and
  check that the dashboard returns.
- Try a small/large OC resolution, and verify Add/Edit numeric input and NEI's
  search text still behave normally.

No server addon or external service is required. Listing reads configuration,
not ME inventory. This release adds no AE2/CPU polling; batches are capped at
64 entries and 4,096 characters, and further limited by the actual screen size.
The receiver takes one frozen configuration snapshot per transfer and reuses it
for retries. It writes only the reply lines, avoiding a full-screen clear for
each entry. Header/log updates respect the reply overlay while it is active.

The client stops reading the screen buffer at the frame terminator and rejects
an ordinary dashboard after its first five characters. Completed data remains
nonce/index/checksum validated and replaces the list only after all pages arrive.
There is no persistent cross-server cache that could expose stale entries.

Compilation, API verification and automated protocol/GUI/Lua tests passed.
Physical gameplay, real network timing and server MSPT have not been measured
for this version. Details and reproducible tests are in VERIFICATION-1.3.0.md.

## Open and use the manager

- **Left Ctrl+Shift+M** from an inventory or NEI container opens the manager.
- **Left Ctrl+M** while hovering an item opens its Add/Edit/Remove editor.
  The editor's **Manage existing entries** button opens the manager.
- Left Ctrl+M without a hovered item also opens the manager.
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
