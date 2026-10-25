> Historical release record for the version named below. For current commands and behavior, use the [project guides](../README.md).

# NEI Level Maintainer 1.3.2

This update reduces idle AE2 queries, protects script updates against failed
file replacement, and adds Low/Target/Batch hover explanations to the client editor.

## Install this version

1. Close Minecraft. In Prism Launcher, open your GTNH instance's Minecraft
   folder and replace the old NEI Level Maintainer JAR in `mods` with
   `nei-level-maintainer-1.3.2.jar`. Keep exactly one version of this addon.
2. On the OC computer, press Q to stop Maintainer. In its installation folder,
   run these two commands to install the matching scripts, including before
   the PR is merged into master:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/nei-level-maintainer-1.3.2/installer.lua installer.lua
installer nei-level-maintainer-1.3.2
```

The optional installer argument selects a branch, tag or commit. Omitting it
continues to install master. Existing config.lua, nei_overrides.lua and settings
values are retained; settings template refresh still asks before changing it.
The installer reboots after a successful installation.

The Lua improvements also work with client 1.3.1; only the hover explanations
require the new JAR. Transport and receiver protocols have not changed. This
remains client-only, using OC's existing clipboard and screen synchronization.

For future master updates after merge, use the usual command:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

## What changed

- When every entry is paused or waiting for its stock/retry/refill deadline,
  the script skips CPU/job queries. Active entries retain their prior cadence.
- The header marks a retained CPU count as `(cached)` rather than implying it
  was just read. An untouched/paused list can show `CPUs: not polled`.
- Downloads are compiled as Lua without executing them before replacement.
  All original scripts are kept until every replacement succeeds. On failure,
  the installer restores the previous scripts and does not reboot. If rollback
  also fails, it preserves `.install-backup` files and prints recovery paths.
- Hover Low, Target or Batch in Add/Edit for an explanation of thresholds,
  request sizing and units. Input, hotkeys, manager listing and pause controls
  retain their existing behavior.

If an interrupted update reports `.install-backup` files, keep them. Restore
those originals to their corresponding paths before retrying; the installer
refuses to overwrite a leftover recovery copy.

## Test in Minecraft

- Open the editor via Ctrl+M over an NEI item, and via Manage existing entries.
  Hover each numeric field and its label; verify the help stays readable.
- Check top-row digits, numpad, selection replacement, Backspace/Delete, and
  Item/Fluid switching. Confirm no text appears in the NEI search bar.
- With stocked entries, watch the header change to `(cached)` on skipped cycles.
  Pause all entries, then resume one and confirm maintenance resumes on its
  normal next cycle. Already submitted AE2 jobs continue while paused.
- Check a low-stock entry refills to Target and a timed refill keeps its cadence.
- Run the version-pinned update and confirm your existing entries/settings
  survive. Automated tests exercise failure recovery without risking your disk.

The API-call reductions are measured in a deterministic test, not a live TPS
benchmark. Full multiplayer gameplay and rendered tooltip appearance still need
in-game confirmation. See VERIFICATION-1.3.2.md for automated checks.
