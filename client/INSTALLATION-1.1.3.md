> Historical release record for the version named below. For current commands and behavior, use the [project guides](../README.md).

# NEI Level Maintainer 1.1.3

Close Minecraft. Replace the older NEI Level Maintainer JAR in the Prism instance mods folder with nei-level-maintainer-1.1.3.jar, then restart Minecraft. Keep exactly one copy.

Numeric fields select all on click. Type top-row or keypad digits, or use Backspace/Delete to clear. Tab changes fields. Test Low, Target and Batch both from Ctrl+M hover creation and from Manage/Edit.

Item/Fluid can now be switched in both screens. For an existing or newly submitted entry, changing its type uses a single atomic receiver update which disables the old type and saves the new one. Names remain fixed for hovered/existing entries; use Manage > Add for a different fluid display name. Fluid quantities use the existing receiver's units.

Update the OC receiver before converting an existing entry's type. Stop Maintainer with Ctrl+Alt+C, then update nei_bridge.lua and restart the computer. Before PR #9 is merged, from the Maintainer installation directory:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/fix/nei-editor-selection/nei_bridge.lua nei_bridge.lua
```

After PR #9 is merged, the normal installer obtains the updated receiver:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

Existing ordinary add/edit/remove commands remain compatible. The new LM2|T conversion command requires this receiver; older receivers ignore it. Preserve config.lua, settings.lua and nei_overrides.lua. No server mod is needed.

Validation: compiled against actual GTNH 2.9 RC2 Minecraft/Forge, NEI 2.8.155-GTNH and OC 1.12.64-GTNH. 12 Java 8 classes, 1,029 bytecode references verified. 31 field checks, 59 editor/render checks, 38 encoder/reply checks, 23 Lua receiver checks and 9 actual OpenOS buffered IO checks passed. Inspected installed lwjgl3ify 3.0.37's text insertion redirect; numeric insertion now calls writeText directly and deletion calls deleteFromCursor, bypassing that buffered redirect. Headless checks do not apply the full pack's mixin transformations or test physical keyboard events. In-game verification remains required.
