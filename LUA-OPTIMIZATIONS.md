# Lua display and clock optimizations

This is an OC script update. Keep your current client JAR. The CPU-polling rollback is preserved; no additional AE2 CPU queries are added. Crafting, stock-check and refill timing stay the same.

Changes:
- Sample the real filesystem clock once per minute; advance the cached timestamp with uptime between samples. This removes per-header/per-log file opens, closes and lastModified calls. Wall-clock adjustments are picked up at the next synchronization.
- Read GPU resolution and depth once per guarded drawing operation; avoid redundant foreground changes within that operation. Metadata is discarded between draws, including errors, to respect resizes and other programs.
- Add settings.headerInterval = 5, updating the table clock/countdown every five seconds by default. Use 1 for the old visual cadence, or 10 for fewer header updates. This is independent of settings.sleep and refillInterval.

After merging the optimization PR, stop Maintainer with Q or Ctrl+Alt+C and run from its installation directory:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The installer preserves configuration values and overrides. Accepting the settings-template refresh adds the documented headerInterval option while retaining your tuned values. Declining still uses the default of 5 if your settings file has no headerInterval. The installer reboots OC.

Before merging, level-maintainer-lua-optimized.zip contains the updated program files; stop Maintainer, back up its directory, copy the contents over it, and reboot OC. No config.lua, settings.lua or nei_overrides.lua is included, so your values are not overwritten. Set headerInterval manually in your existing settings.lua if desired.

Validation: the timestamp and GPU-query regressions fail against the previous code and pass after the change. Ten Lua 5.2 suites pass, including unchanged maintenance/refill schedules, header interval validation, settings preservation, clock drift correction/failure backoff, and an exact screen-character/color comparison across 20 render scenarios. The 23-row render uses 8 -> 2 resolution/depth queries; text writes/fills are unchanged. This measures component-call counts in a simulated boundary, not server MSPT. Profile under a similar crafting workload before and after; no specific improvement to the reported 0.5 ms is promised.
