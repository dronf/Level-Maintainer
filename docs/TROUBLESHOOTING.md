# Troubleshooting

[Overview](../README.md) - [Installation](INSTALLATION.md) - [Configuration](CONFIGURATION.md)

## No reply, slow listing or encoded text on the screen

Keep Maintainer running with nei_bridge.lua installed, and restart OC after
updates. Use the full screen UUID bound to its active GPU, open that physical
screen once, and stay in normal interaction range/permissions. Refresh after
the buffer synchronizes. A tiny resolution may not fit an entry reply.

Clients 1.3.0+ request batches; older receivers can trigger a slower fallback.
Listing includes clipboard delivery, screen writes, synchronization and client
ticks. Reading 20 / 23 counts configuration entries, not ME inventory items.
Cancel/close, or wait for the five-second session timeout and dashboard redraw,
to restore normal text. Another client/config mutation can invalidate a snapshot.

## Submitted but unchanged / Save failed: nil

Submitted means the client sent the command, not that OC saved it. Look for
Updated/Removed/Paused/Resumed on OC or refresh the manager. Inspect any Save
failed / Reload failed message. Check free disk space and filesystem access.

Older receivers treated a successful OpenOS nil close as failure. Current code
flushes explicitly and accepts nil-without-error closes. Update all scripts and
restart; replacing only the JAR does not update the receiver.

NEI overrides take precedence over config.lua. Editing the base file may appear
ineffective until its override is edited/removed. Invalid overrides are reported
and preserved. Back up config.lua, settings.lua and nei_overrides.lua together.

## Keyboard, duplicate digits, NEI search input or white button stripe

Keep exactly one current addon JAR. The client includes focus isolation, top-row
and numpad handling, duplicate-character suppression, lwjgl3ify shared-buffer
cleanup and custom wide button drawing. These require a JAR update; downloading
only nei_bridge.lua cannot change client input/rendering.

Click a field, replace the selection, use Backspace/Delete or Tab. Use plain
whole numbers, not 10k. Item/Fluid switching works in creation and editing;
existing names stay fixed. Hover editors start with saved local defaults.
Manage -> Edit loads actual OC values.

For persistent problems, record the JAR version, exact keys, opening path
(NEI hover or manager), and latest log/crash. Values in a screenshot alone do
not show whether a submitted update was acknowledged by OC.

## Stock, Target or CPU count looks wrong

Stock is sampled, not live; gray is an older observation. Partial craft output
may accumulate before the next stock check. Want shows Low while idle and Target
while refilling. Stock >= Low is satisfied unless refill was already active.
Restarting resets refill state. Low 0 does not trigger at zero. The 1.3.4 low-load profile intentionally checks
stocked entries only every 5-60 minutes; slow detection can be expected behavior.
Lower thresholdIntervals/sleep for critical stock.
See [examples](CONFIGURATION.md#low--target--batch).

CPU counts are snapshots, labelled cached on skipped passes. The script does
not rescan after every request. Wait for the next due pass, check exact cpuName,
CPU size and Crafting Monitor current-output reporting. An idle CPU may not fit a job.

## Not craftable, failed request or no link

Check the exact label, pattern visibility and network connection. Both hits and
missing craftables are cached up to cacheDuration, default 3,600 seconds. Restart
Maintainer to clear the cache immediately after changing patterns; R alone
checks saved file changes.

A failed request waits retryDelay. Check the Recent reason, ingredients, pattern
correctness, CPU size/availability and machine inputs/outputs. A no-link result
means the OC/AE2 request did not return a usable crafting link; that alone does
not identify a root cause. Inspect AE2's crafting interface and adjacent log
messages for CPU selection, changing network or calculation/submission failures.

Do not encode chance outputs as guaranteed pattern results. AE2 can wait for
an output that a recipe roll did not produce. The maintainer does not repair
patterns or guarantee probabilistic byproducts.

## Large text, GPU upgrades and overflow

fit selects large text for the current row count. Use fixed or columns to retain
resolution. Both GPU and screen must support the desired resolution. Overflow
uses pages; Page Up/Down or arrows page the dashboard. Disable showRecent to
free space. Manager paging separately uses mouse wheel or Prev/Next.

## Computer stopped or keeps restarting

Check power, RAM, disk space and the Lua error. Unexpected errors normally log
and restart after retryDelay, at least five seconds. Q and Ctrl+Alt+C stop
intentionally. Startup config errors wait for repair. Auto-start runs at boot;
wake-on-redstone also needs a redstone card, a rising signal and available power.
Neither repairs a broken configuration.

## Minecraft startup or multiplayer-screen crash

Read the first exception and affected screen, not just the loaded-mod list.
Keep one addon JAR and record GTNH, Java/runtime, NEI and OC versions.

A reported 1.3.2 crash occurred after addon initialization in
GuiMultiplayer -> OldServerPinger -> NetworkManager.flushOutboundQueue, with a
null queued packet. This points to server-list networking and does not establish
an addon defect. Retry first; if repeatable, compare against the previous addon
or a temporarily disabled-addon run. Keep the crash report and latest.log.
1.3.3 does not contain a networking crash patch.

Report reproducible addon failures with the complete crash, preceding log,
installed JAR and script version/ref, and the action that triggered it. Remove
private server details and credentials before publishing logs.
