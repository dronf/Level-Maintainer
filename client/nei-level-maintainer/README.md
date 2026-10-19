# NEI Level Maintainer 1.1.2

Client-only Minecraft 1.7.10 addon for GTNH 2.9 RC2, NEI 2.8.155-GTNH and
OpenComputers 1.12.64-GTNH. Includes an editor and a searchable, paginated manager
that reads the computer's real configuration, including base config entries and
NEI overrides. No new server mod, network channel or external service is required.

## Upgrade both sides

**1.1.2 is a client-only correction.** If the OC computer already has the PR #8
save fix, replace only the client JAR and restart Minecraft. No new Lua files
are needed. Numeric clicks now select the whole value even when that field was
already focused; this includes the initially focused Low field. Previously a
click there cleared selection and typed digits were inserted into the old value.
Hover add and existing-entry edit use the same locked-name field layout.

Release Ctrl+M before editing: hotkey opening is deferred until the old NEI input
event has finished and the shortcut keys are released. Wide buttons now use
solid rectangle drawing, avoiding the white center stripe caused by stretching
Minecraft's vanilla 200-pixel button texture beyond its supported width.

The following script-update instructions apply when upgrading an older OC
installation; an already updated computer does not need another update for 1.1.2.

1.1.1 corrects OpenOS save failures (`[NEI LM] Save failed: nil`). The receiver
now explicitly flushes and accepts a nil close result without an error. Existing
entries are preserved on genuine write, flush or close failures. The installer
also handles OpenOS closes when refreshing settings. Update the scripts even
if you keep the 1.1.0 client JAR; persistence requires this script correction.

The 1.1.1 client also makes focus explicit, selects numeric values when entering
a field, supports keypad scan codes without a character, and normalizes reversed
selections to work around a vanilla length-limit replacement bug. Once the UUID
is filled, Low is initially selected. Tab/Shift+Tab and Ctrl+A work in the editor.

1. Close Minecraft. Remove older NEI Level Maintainer JARs from the instance's
   Mods list and add `nei-level-maintainer-1.1.2.jar`. Keep the pack's NEI and OC.
2. On the OC computer, stop Maintainer with Ctrl+Alt+C. Back up its directory.
   After the companion script PR is merged, run this from that directory:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The installer preserves existing configuration and overrides and reboots. Before
that PR is merged, use the supplied `level-maintainer-oc-1.1.1.zip`: copy
`Maintainer.lua`, `nei_bridge.lua`, and `src/` into the existing installation,
preserving `config.lua`, `settings.lua` and `nei_overrides.lua`. Then restart OC
to clear Lua's cached modules. New installs also need the supplied configuration
examples copied to `config.lua` and `settings.lua`.

Run Maintainer from its installation directory. Leave it running during every
NEI operation. Do not leave the computer in the `lua>` interpreter; clipboard
commands sent there become pasted text, not maintenance requests.

## Open and use the manager

- **Left Ctrl+Shift+M** from an inventory or NEI container opens the manager.
- **Left Ctrl+M** while hovering an item opens its Add/Edit/Remove editor.
  The editor's **Manage existing entries** button opens the manager.
- Left Ctrl+M without a hovered item also opens the manager.
- Enter the OC screen UUID and click **Refresh**. A saved UUID is reused and
  refresh starts automatically when opening the manager.
- Filter the loaded list by name; use Prev/Next to page. Click a row to select
  it, then **Edit** or **Remove**. Remove requires a second **Confirm?** click.
- **Add** opens an editor where you can enter an exact display name and choose
  Item or Fluid. Hovering an NEI item prefills its name. Set Low, Target and Batch
  and click Save to OC. Existing names and types are fixed while editing.
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
