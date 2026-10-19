# NEI Level Maintainer 1.1.5

Client-only Minecraft 1.7.10 mod built against actual GTNH 2.9 RC2, NEI 2.8.155-GTNH and OpenComputers 1.12.64-GTNH dependencies.

Close Minecraft. Remove the older NEI Level Maintainer JAR from the Prism instance mods folder, add nei-level-maintainer-1.1.5.jar, and restart Minecraft. Keep exactly one copy of the addon. No additional Lua update is required if the OC receiver was updated for 1.1.3. For older OC installations, run the normal installer from the Maintainer directory, preserving your configuration and overrides:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The 1.1.5 changes clear leftover numeric characters from lwjgl3ify's shared SDL text buffer, release NEI's search/widget focus while editing, reassert the active field even when its vanilla focus flag is already true, and blur fields on close or resize. Stale container key callbacks are forwarded to the visible editor and consumed before NEI's search handler. Numeric keys still use only physical events to prevent doubled digits. Non-numeric text fields retain normal text input.

The manager previously waited another 100 ms after every successful entry reply. That wait is removed. Reading 20 / 23 means it is fetching entry 20 of 23 through the existing OC clipboard request/screen reply path. It still waits for one round trip per entry; network/server ticks, OC execution and screen synchronization affect elapsed time. The screenshot does not measure crafting throughput. No GPU/CPU upgrade is required by this change.

Test both Ctrl+M hover creation and Manage > Edit. Click Low, Target and Batch, replace the number with top-row digits and then keypad digits, clear it using Backspace/Delete, and save. Also test Tab, repeated digits, closing/reopening, and resizing. Return to NEI: its previous search text should remain unchanged, with none of the typed amounts appended. Refresh the manager and check the loaded entry count and values.

No server-side mod, new network channel or external service is used. Leave Maintainer running on the OC computer during NEI operations.
