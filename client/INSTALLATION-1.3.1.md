> Historical release record for the version named below. For current commands and behavior, use the [project guides](../README.md).

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
