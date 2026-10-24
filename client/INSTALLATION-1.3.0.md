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
