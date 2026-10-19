# Level Maintainer CPU availability update

This is an OC Lua script correction. Keep the existing client JAR; no server mod is needed.

The old header started with a per-cycle CPU snapshot, subtracted successful requests, and retained that estimate during the countdown. A short job could finish and leave a real CPU idle while the header still said 0. The old scheduler also gated entries on CPU availability before reading stock, producing misleading waiting-for-CPU rows for items already above their target.

The correction uses actual getCpus observations instead of permanent per-pass subtraction, checks stock before capacity, and refreshes CPU/job availability immediately before needed submissions. It refreshes the header after the pass and approximately once per second during the table countdown. Countdown refreshes do not query every CPU's finalOutput. Named CPU restrictions remain in force; the header counts the whole network. Row statuses remain the result of the last maintenance check, so a newly idle CPU can appear before the next scheduled entry check. An idle CPU is not necessarily large enough for a particular job.

After merging the CPU availability PR, stop Maintainer with Q or Ctrl+Alt+C and run from its installation directory:

```sh
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua installer.lua && installer
```

The installer preserves existing configuration/overrides and reboots. Before merge, level-maintainer-cpu-fix.zip contains the updated scripts: stop Maintainer, back up the installation, and copy its contents over the installation directory. The ZIP contains no config.lua, settings.lua or nei_overrides.lua. Restart the OC computer afterward. Maintainer.lua and src/AE2.lua must be updated together.

Test with one CPU and two short craftable entries below target: a completed first craft should let the second entry use the CPU in the same pass. With all CPUs occupied, an entry already above target should show stocked. Watch a job finish during the countdown: the header should change to show the idle CPU before the next cycle. Check a named-CPU configuration separately; another idle CPU must not bypass the name restriction.

Validation: the new regression fails on the previous script with 'fast completed jobs must release CPU within a pass'. The fix passes 15 focused checks running the actual main loop and AE2 adapter with a simulated OC/AE2 boundary, plus existing maintenance, refill timing, receiver, manager, OpenOS IO, display, settings and installer suites under Lua 5.2. Physical-server timing remains unverified. No new OC/AE2 component methods are used.
