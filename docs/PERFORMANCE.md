# Performance and tuning

[Overview](../README.md) - [Settings](CONFIGURATION.md#every-setting-and-default)

The maintainer submits normal AE2 crafting calculations. Expensive patterns and
frequent small requests can affect server load. Compare MSPT under equivalent
workloads; component-call reductions are not live TPS measurements.

There is no enforced OC component tier. Additional RAM helps large entry lists;
higher-tier GPUs and screens primarily increase display capacity. Faster OC
execution can reduce script overhead, but does not shorten AE2 processing
recipes or change configured polling intervals. The
[component requirements](INSTALLATION.md#requirements) distinguish mandatory
hardware from the optional internet/redstone cards.

## Default low-load profile

The 1.3.4 template and runtime fallbacks use sleep=60, headerInterval=60,
retryDelay=300, cacheDuration=3600, pollInterval=5 and
thresholdIntervals={300,600,900,1800,3600}. logSkips=false, logRepeats=false,
requireFreeCpu=true and reloadCheck=0 avoid optional repeated work. Fresh config
contains no active entries and no fast refillInterval by default.

These are deliberately infrequent checks, not a measured universal optimum.
A stocked item may wait up to its 5-60 minute interval plus a cycle/pass after
sudden consumption. Failed jobs retry after five minutes. Pattern changes can
remain cached for an hour; restart Maintainer for immediate discovery. Polling
an in-progress calculation every five seconds can delay the next entry.

Updates preserve existing saved values, so accepting a template refresh does
not by itself adopt the new timings. See [the opt-in settings block](INSTALLATION.md#update-later).

## Recommended tuning

1. Increase Batch where ingredients, machines and CPU storage permit. Fewer
   large requests usually require fewer calculations than many tiny requests.
2. The default sleep is 60 seconds. Increase it further if slower response is acceptable; lower it only for faster replenishment.
3. Keep requireFreeCpu=true to avoid calculations with no idle CPU in the snapshot.
   Disabling it does not remove job-detection queries.
4. Retain or lengthen adaptive thresholdIntervals for noncritical stock. Sudden
   withdrawals can wait the interval plus a cycle/pass before detection.
5. Use nil-threshold continuous Lua entries for genuinely continuous lines.
   They skip stock comparisons but still detect jobs/CPUs and submit calculations.
6. Avoid very short refillInterval values unless needed. Active timed refills
   refresh CPU/job snapshots on their own schedule.
7. Increase headerInterval for fewer cosmetic updates. showRecent=false and
   logSkips=false can reduce display/log work; they do not speed recipe processing.
8. Consider an appropriately sized dedicated CPU or subnet if it fits your AE
   design. Preserve ingredient, machine, storage and channel visibility.

## Current optimizations

- Cached targeted craftable lookups/output stacks, including negative lookups.
- Targeted item/native-fluid stock checks, without whole-inventory scans.
- Adaptive stocked delays; crafting and retry waits skip stock reads.
- One CPU list per due pass; only busy CPUs need current-output queries.
  Accepted requests reserve the snapshot's CPU budget for the rest of that pass.
- No CPU/job scan when every entry is paused or waiting for an existing deadline.
- Rotating order, failed-request backoff and suppression of overlapping observed
  jobs for the same label.
- Filesystem wall-clock sampling once per minute, advanced using uptime between samples.
- GPU metadata reused within a guarded draw, redundant foreground changes skipped.
- Cosmetic headers every 60 seconds by default, separate from maintenance.
- Manager replies batched within screen area, 64-entry and 4,096-character limits.

The additional CPU-rescan approach was rolled back. This package does not restore
it. An apparently idle CPU may therefore remain unused until the next due
snapshot, trading some responsiveness for fewer server calls.

## Measured calls and limits

| Deterministic scenario | Before | Current |
| --- | --- | --- |
| 23 stocked entries / 300 seconds / 10-second cycles / 300-second cooldown | 30 CPU snapshots | 1 |
| Entirely paused or empty list in that interval | 30 CPU snapshots | 0 |
| An active maintained job in that interval | 30 CPU snapshots | 30 |
| 23-entry manager list at 80x25 | 24 exchanges | 1 |
| Same list at 50x16 | 24 exchanges | 2 |
| 23-row fixed-layout draw: resolution/depth queries | 8 | 2 |

Name length and resolution affect batch capacity. Clipboard cooldown, packet
delivery, OC writes, screen synchronization and client ticks still take time.
The list reads configuration, rather than querying live stock for every row.

See [1.3.0 results](../client/VERIFICATION-1.3.0.md),
[1.3.2 results](../client/VERIFICATION-1.3.2.md) and
[reproduction instructions](DEVELOPMENT.md).
