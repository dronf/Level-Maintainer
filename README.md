# Infinite Maintainer

Lets you passive lines easily, without lag and randomness of AE2 maintainer.
Also supports having a threshold.

Fork of [Echoloquate/Level-Maintainer](https://github.com/Echoloquate/Level-Maintainer) with fixes for the lookup cache, NBT item and fluid thresholds and crash recovery, a `settings.lua` for timing, retry and CPU options, and optional auto-start.

# Setup

## Hardware

- An OpenComputers computer: case, CPU, RAM, hard drive, EEPROM (Lua BIOS), GPU, screen and keyboard
- An internet card (needed to download the scripts)
- An adapter touching a full-block ME interface on your network
- A Crafting Monitor on every crafting CPU (used to see what is already being crafted)
- Optional: a redstone card and a slow redstone clock, to turn the computer back on after a power loss (see [Auto-start and crash recovery](#auto-start-and-crash-recovery))

## Install OpenOS

The maintainer runs on OpenOS, so install it to the hard drive first:

1. Get the OpenOS floppy. It is normally crafted from a blank floppy and the OpenComputers manual (check NEI for the recipe in your pack).
2. Put the floppy in a disk drive next to the computer and turn it on.
3. Run `install`, pick the hard drive and let it reboot.
4. Remove the floppy. The computer now boots OpenOS from the hard drive.

# Installation

Download it (run the same command again later to update)

```bash
wget -f https://raw.githubusercontent.com/dronf/Level-Maintainer/master/installer.lua && installer
```

The installer replaces the scripts and keeps an existing `config.lua`. When the
settings template has new options or updated explanations, it offers to refresh
`settings.lua`, preserving your values (including `thresholdIntervals` tables and
custom settings) and saving the previous file as `settings.lua.old`. Declining
keeps your settings unchanged; an unreadable file is also left untouched.
It then asks:

- **Start Maintainer automatically when the computer boots?** Adds a line to `/home/.shrc`.
- **Turn the computer on when it receives a redstone signal?** Only asked when a redstone card is installed.

Then it reboots.

Run it from the folder you installed to (not needed if auto-start is on)

```bash
Maintainer
```

Stop it by pressing Q, or holding Ctrl+Alt+C for a second. Crafts already sent to AE2 keep running.

# Screen and keys

By default the screen shows a status table, redrawn every cycle:

```
Level Maintainer   14:02:11   CPUs free: 2/8   Entries: 3   Next cycle in 7s
Name                          Stock     Want   Batch  Status
Blank Pattern                   385      256     512  stocked
Fluorescent Dye                   -        -    1024  crafting
Phthalic Acid                11.97M   10.00M   3.00M  stocked
-- Recent --------------------------------------------------
[14:01:51] Requested Fluorescent Dye x 1024
E edit config  S edit settings  R reload  Q quit
```

- **Stock** is shown for entries with a threshold (the maintainer only reads the stock when it has to compare it). Fluids are in mB. The stock isn't read while an entry is crafting, waiting to retry or waiting for a CPU; its last value is then shown in gray.
- **Status** is one of: `stocked`, `paused`, `crafting`, `requested`, `waiting for CPU`, `failed` (the Recent log says when it is retried), `not craftable`, `error`, or `waiting` before the entry's first check.
- Rows that need attention (`failed`, `error`, `not craftable`) are listed first; the rest are alphabetical.
- The header counts down to the next cycle.
- By default (`settings.layout = "fit"`) the maintainer picks the screen resolution itself, so the table fills the screen with text as large as possible; with few entries the text is big, with many it gets smaller. `"columns"` instead keeps the resolution and splits the rows into side-by-side tables on wide screens. On a screen that is taller than wide (e.g. 2x3 blocks) `"fit"` uses narrower columns and short status words, so the text can be larger; `"tall"` uses them on any screen.
- With a color GPU the rows are colored by status. If there are more entries than fit, the table has pages: the header shows `Page 1/3`, and Page Up/Down or the Up/Down arrows switch pages. `settings.showRecent = false` gives the table the whole screen.

Set `settings.display = "log"` for the plain scrolling log instead.

Keys work while the maintainer waits between cycles (and while it waits at startup for an ME interface or a fixed `config.lua`):

| Key | What it does |
|---|---|
| E | Opens `config.lua` in the editor. Save with Ctrl+S, close with Ctrl+W; the maintainer reloads it and starts a new cycle. |
| S | Same for `settings.lua`. |
| R | Reloads `config.lua` and `settings.lua` if they were saved since they were last read (e.g. edited from your PC). |
| Q | Stops the maintainer. |
| Page Up/Down, Up/Down arrows | Switch pages of the status table when it doesn't fit on the screen. |

Each cycle starts one entry further down the list, so when crafting CPUs are scarce every entry gets its turn at a free CPU.

# Auto-start and crash recovery

While running, the maintainer recovers from problems by itself:

- An ME interface that is removed or replaced, or an AE2 error on one entry, is logged and retried on the next cycle.
- Any other unexpected error is logged, and the maintainer restarts after `retryDelay` seconds (at least 5).
- If no ME interface is attached when it starts, it waits for one instead of exiting.
- Server restarts and chunk unloads are fine: OpenComputers saves the running computer and resumes it.
- A broken entry in `config.lua` (for example a missing batch size) is reported and skipped; the other entries keep running.
- At startup, a mistake that stops `config.lua` from loading at all is reported and the maintainer waits for the file to be fixed instead of exiting. With live reload on, a mistake in a reloaded file is reported and the last working version stays in use.

It only stops when you press Ctrl+Alt+C.

## Start on boot

Answer yes to the first installer question, or add this line to `/home/.shrc` yourself (use the folder you installed to):

```bash
cd "/home" && Maintainer
```

Delete that line to turn auto-start off.

## Turn back on after a power loss

A computer that runs out of power switches off and stays off. To have it switch itself back on:

1. Put a redstone card in the computer.
2. Answer yes to the redstone question in the installer, or run `lua` and enter `require("component").redstone.setWakeThreshold(1)`. The card remembers this.
3. Wire a slow redstone clock (one pulse every 30-60 seconds) into the computer.

Each pulse turns the computer on if it is off; a running computer ignores it. With auto-start on, the maintainer starts with it.

# Config

## Browser config editor

The [Config List editor](docs/index.html) builds `config.lua` without editing Lua
by hand. Download the repository and open `docs/index.html` in a browser, keeping
`docs/config.js` beside it. No Minecraft mod or server installation is needed for
the editor. It works offline and stores named lists in that browser; export a
backup before clearing site data or changing browsers.

- Enter **Name**, **Maintain / Low**, and **Batch Amount**. Hover an item or fluid
  in NEI and press Ctrl+C to copy its label.
- Leave **Refill target** blank for ordinary threshold behavior. Set it to use
  this fork's low/target hysteresis: start below Low, then refill to Target with
  each request capped by Batch. In simple mode, blank/0 Maintain means continuous
  crafting; with a Target, Low 0 is an actual zero threshold.
- Choose the item/auto-detected-fluid or fluid section. An optional registry-name
  override supports old fluid drops and ambiguous fluid labels.
- Set **Refill interval** to positive seconds (for example `2` or `0.5`) to check
  that entry more frequently while actively refilling. It requires a Target;
  leave it blank to retain ordinary cycle timing. The value is preserved in
  imports, saved lists, backups, and share links.
- Inputs accept `k`, `m`, `g`/`b`, and `t`; the generated file uses **plain Lua
  numbers**, so no new config parser is required in OpenComputers.
- Import positional or named low/target entries, including multiline entries and
  disabled lines. Unsupported expressions or entries stop the entire import
  with an error. The editor does not execute imported Lua.
- Download the full file, copy it, or use **Copy next part** for OpenComputers'
  1,024-character paste limit. Press E in the maintainer, replace the existing
  file contents, paste the parts in order, save with Ctrl+S and close with Ctrl+W.
- Backups preserve refill targets, item/fluid sections, overrides, and disabled
  entries. Old upstream/PowerShell backups can also be imported.
- Share links work when the editor is served over HTTP(S). For local files use
  backup export/import instead. GitHub Pages can serve the `docs/` directory if
  hosting is enabled for the repository; this change does not enable hosting.

The editor is adapted from [Willshaper's Config List editor](https://github.com/Willshaper/Level-Maintainer/tree/ba32287d00dabf15ca6f96756d7cf9f0bc2c10d6/docs),
with compatibility for this fork's refill targets and standard Lua loader.

## Config format

You can change maintained items in `config.lua`. There are two blocks, `cfg.items` and `cfg.fluids`. Items and fluids work in either one: the maintainer checks what each entry actually is and uses the right stock check. The simplest setup is to put everything in `cfg.items`.

## Items

```lua
cfg["items"] = {
    ["Osmium Dust"] = {nil, 64},                                  -- no threshold
    ["drop of Molten SpaceTime"] = {1000000, 1, "spacetime"},     -- fluid drop with threshold + fluid name
}
```

Pattern: `["item_label"] = {threshold, batch_size, fluid_name?}`. The third value is only needed for `ae2fc:fluid_drop` items and is the fluid's registry name -- this path works on any GTNH version.

## Fluids (GTNH 2.9+)

GTNH 2.9 unified items and fluids in the OpenComputers AE2 integration, so fluid craftables can now be requested directly without going through `ae2fc:fluid_drop`. Threshold checks use real fluid amounts in mB.

```lua
cfg["fluids"] = {
    ["Molten SpaceTime"] = {1000000, 1000},
}
```

Pattern: `["fluid_label"] = {threshold_mb, batch_mb[, fluid_registry_name]}`. The label is the fluid's display name as shown in the AE crafting terminal. The fluid registry name is auto-detected from the craftable's stack -- pass it as a third value only as an override if auto-detection ever resolves to the wrong fluid. Omit the block entirely on pre-2.9 setups (the maintainer skips it with a warning there). Fluids can also go in `cfg.items` with the same values.

## Settings

Timing and behaviour live in `settings.lua` (anything missing falls back to a default):

| Setting | Default | What it does |
|---|---|---|
| `sleep` | `10` | Seconds between cycles. |
| `headerInterval` | `5` | Seconds between table clock/countdown updates; cosmetic only. `1` restores smoother updates. Crafting and refill deadlines are unchanged. |
| `retryDelay` | `60` | Seconds to wait before recalculating an entry whose request failed (missing ingredients, no suitable CPU). `0` retries every cycle. |
| `requireFreeCpu` | `true` | Only start a calculation when a crafting CPU (or `cpuName`) is idle. |
| `cpuName` | `nil` | Send every request to this named crafting CPU. `nil` lets AE2 pick. |
| `cacheDuration` | `600` | Seconds craftable lookups are cached. New patterns are picked up after at most this long. |
| `pollInterval` | `1` | Seconds between checks while AE2 calculates a request. |
| `logSkips` | `true` | Log entries skipped for being in progress, stocked, waiting to retry or waiting for a CPU. |
| `display` | `"table"` | `"table"` shows the status table described under [Screen and keys](#screen-and-keys); `"log"` shows a scrolling log. |
| `showRecent` | `true` | Show the recent log lines below the status table. `false` gives the whole screen to the table. |
| `cpuDisplay` | `"free"` | How the header counts crafting CPUs: `"free"` shows idle CPUs (`CPUs free: 9/11`), `"busy"` shows CPUs running a job (`CPUs busy: 2/11`). |
| `layout` | `"fit"` | How the status table uses the screen. `"fit"` changes the screen resolution so the rows fill the screen with the largest text that fits (matched to the screen's shape; the old resolution comes back when the maintainer stops). On a screen taller than wide it uses the narrow columns of `"tall"`. `"columns"` keeps the resolution and puts the rows in side-by-side tables when the screen is wide enough. `"fixed"` keeps the resolution with one table. `"tall"` is `"fit"` that always uses narrow columns and short status words (`no CPU`, `no pattern`); long names are cut to fit. |
| `logRepeats` | `false` | Show everything that happens, every cycle, in the Recent panel of the status table. `false` logs each entry's status once and again only when it changes. The scrolling log (`display = "log"`) always logs each status once. |
| `reloadCheck` | `0` | Live reload: seconds between checks for a saved `config.lua` or `settings.lua` while running, e.g. `30`. Only useful if you can edit the files outside the game. `0` = off. |
| `utcOffset` | `0` | Hours added to UTC for log timestamps (e.g. `1` for CET, `2` for CEST). Timestamps use the server's real clock, not in-game time. |

**!! Threshold has a performance impact -- only add it when necessary, and preferably not on mainnet !!**

## Lower display and timestamp overhead

The real clock is sampled from the filesystem once per minute, then advanced
using `computer.uptime()`. Log lines and countdown updates reuse that anchor
instead of opening a file for every timestamp. A failed resync keeps the previous
anchor and backs off; real-clock adjustments are picked up at the next resync.

GPU resolution and depth are sampled once per guarded drawing operation and color
changes are skipped when redundant within that draw. The cache is discarded after
each operation, including failures, so later resizes and screen ownership changes
are observed. A 23-row fixed-layout test reduces metadata queries from 8 to 2;
text writes and fills remain the same. Screen characters/colors match the previous
renderer across 20 combinations of layouts, color depth and paging.

`settings.headerInterval = 5` reduces cosmetic table updates from once a second to
once every five seconds. Use `1` for the old cadence, or a longer interval for less
display work. This does not poll CPUs, change stock checks, or postpone scheduled
refill wakes. The CPU polling rollback remains in place. These are component-call
reductions, not a measured reduction in server MSPT.

To reproduce the optional renderer comparison, obtain the pre-change
`src/Display.lua` from commit `52208f2` and run
`lua tests/display-equivalence.lua /path/to/old-Display.lua`.

## Changing the config while it runs

No reboot or restart is needed: press E while the maintainer runs to edit `config.lua` (S for `settings.lua`), save with Ctrl+S and close with Ctrl+W. The maintainer reloads the file and carries on. The files are also read fresh every time the maintainer starts.

### Live reload (off by default)

If you edit the files outside the game (singleplayer, or a server on your own PC), press R to load the changes, or let the maintainer pick them up by itself: set `reloadCheck` in `settings.lua` to how often to check, e.g. `30` seconds, then edit the file in the world save: `saves/<world>/opencomputers/<drive address>/home/config.lua` (run `df` in OC to see the drive address). At the next check the maintainer logs

```
Reloaded config.lua (1 added, 0 changed, 0 removed)
```

and starts a new cycle with it. If a saved file has a mistake, it logs the error and keeps using the previous version until a fixed one is saved.

On a server you usually can't reach these files, so leave it off.



## Adaptive polling and refill targets

Existing `{threshold, batch, fluidName?}` entries still request the fixed batch
whenever stock is below the threshold. `{nil, batch}` keeps continuous production.
Stocked entries now wait between targeted inventory checks instead of querying
on every cycle. No bulk inventory scans or storage event subscriptions are used.

For optional hysteresis, use named fields in either `cfg.items` or `cfg.fluids`:

```lua
["Osmium Dust"] = {low = 10000, target = 15000, batch = 1000},
-- Native fluid amounts and batches are in mB:
["Molten SpaceTime"] = {low = 100000, target = 150000, batch = 10000},
-- For fluid drops in cfg.items, supply the registry name:
["drop of Molten SpaceTime"] = {
    low = 100000, target = 150000, batch = 10000, fluidName = "spacetime"
},
```

Production starts strictly below `low`, then continues until observed stock
reaches `target`, even if it has already recovered above `low`. Each request is
`min(batch, ceil(target - stock))`: batch is a cap on each job, so choose a larger
batch to reduce crafting calculations. Recipe rounding and simultaneous producers
may still overshoot the target. Stock is refreshed after completed crafts; failed
requests retain refill state and use the existing retry cooldown. On restart,
refill state resets: stock between low and target stays idle until it drops below
low again. Changing an entry also resets its state; unchanged entries retain it
across config reloads. The UI's Want column shows low while idle and target while
refilling. Gray stock is the last observation, not a live inventory value.

`settings.thresholdIntervals = {15, 30, 60, 120, 300}` sets the seconds between
stock checks for stock/low ratios below 1.25, 2, 5, 10, and otherwise. Set every
value to 0 to check each cycle. With low = 0, the last interval applies. The main
cycle interval (`settings.sleep`, normally 10 seconds) still controls CPU polling
and rounds stock checks to the next cycle. A sudden large withdrawal may therefore
wait up to its scheduled interval plus one cycle before replenishment starts;
choose shorter intervals for critical stock. Entries currently crafting or in a
retry cooldown do not query inventory. CPU availability checks, fairness, cached
craftables, and error recovery remain in place.

### Faster checks during active refills

Add an optional per-entry `refillInterval`, in real seconds:

```lua
["Osmium Dust"] = {
    low = 10000, target = 20000, batch = 1000, refillInterval = 2
},
```

Idle stock checks still use `thresholdIntervals` and the normal cycle. After stock
falls below `low`, this entry checks on its own two-second schedule until it reaches
`target`, even when `settings.sleep` is longer. Other entries keep their normal
cycles and stock-check intervals. The timer checks whether the previous craft has
finished, then submits the next batch if needed; it never queues overlapping jobs
for the same label. The final request remains capped by the remaining amount to
target. A busy CPU or crafting calculation can delay submission; a failed request
keeps its `retryDelay` cooldown. CPU/job snapshots are refreshed on timer wakes,
but unrelated entries do not query stock or submit jobs on those wakes.

Use a finite positive number; fractional seconds such as `0.5` are supported.
The option requires `low` and `target`; it is not valid on continuous-production
entries. Omit it to retain existing behavior. Choose an interval shorter than the
expected batch duration to reduce the gap between crafts. Very short intervals
increase CPU/job checks and display updates, so start with one or two seconds.
Missed slots are skipped: each deadline starts after the preceding check finishes,
with no burst of catch-up requests. When several timed refills are due together,
their order rotates so they share available CPUs.

Unchanged entries retain active refill state and deadlines across config reloads.
Changing `refillInterval` resets that entry's refill state, like changing its target;
it reactivates on a normal stock check below `low`. Restarting resets refill state.

The installer and installation command use this fork. Settings refreshes preserve
your polling intervals and refill configuration; declining a refresh keeps your
file, with defaults supplying missing options.

### Validation

Run these from the repository root (Lua 5.2+ and Node.js):

```sh
lua tests/maintenance.lua
lua tests/pause.lua
lua tests/refill-interval.lua
lua tests/settings.lua
lua tests/installer.lua
lua tests/nei-bridge.lua
lua tests/nei-manager.lua
lua tests/nei-batch.lua
lua tests/display.lua
lua tests/utility.lua
node tests/config-editor.cjs
```

Optional browser integration tests require Playwright and its Chromium browser:
`node tests/browser-editor.cjs`. Set `PLAYWRIGHT_CHANNEL=chrome` to use an installed
Chrome instead. These cover persistence, target editing, backups, share links,
atomic imports and mobile layout; screenshots are written to a temporary folder.

Use `settings.layout = "wide"` to retain full-width name columns on tall screens;
`"fit"`, `"tall"`, `"columns"`, and `"fixed"` continue to work as before.

Tests mock the OC/AE2 boundary; testing on a running GTNH server is still required
for real crafting behavior and server-load measurements.

### NEI clipboard receiver

The installer includes `nei_bridge.lua` alongside `Maintainer.lua`; both are
required even when you do not use a client editor. The receiver accepts the PR #5
`LM1|I|name|low|target|batch` protocol through OpenComputers' existing clipboard
event. It saves overrides in `nei_overrides.lua` in the working directory and
reloads the active configuration. Start Maintainer from its installation directory.
Overrides take precedence over matching display names in `config.lua`.

Quantities up to 10^12 are serialized without Lua 5.2's platform-dependent `%d`
integer narrowing. The receiver test covers persistence, merge precedence,
invalid requests, save rollback and reload failure. It can also consume commands
generated by a Java client test: `lua tests/nei-bridge.lua commands.txt`.

### NEI manager (client addon 1.3.1)

The companion client addon in [client/nei-level-maintainer](client/nei-level-maintainer)
adds a searchable, paginated view of the real configuration with Add, Edit, Pause/Resume and
confirmed Remove actions. Ctrl+M opens the manager during normal gameplay.
In an inventory/NEI GUI, Ctrl+M over an item opens its editor and Ctrl+Shift+M
opens the manager. Either Ctrl key works; release the shortcut to open it.
Chat and OC terminals retain their own input. The 1.3.1 hotkey update needs
only the client JAR when the 1.3.0 OC scripts are already installed.

Select a row and click **Pause** to keep it configured without submitting new
crafting requests. The row stays visible with a purple **[Paused]** prefix in the
manager and purple **paused** status on the OC dashboard. **Resume** enables it
again. Already-submitted AE2 jobs finish normally. Paused entries do not query
stock; their last known stock can remain visible. This adds no extra CPU polling.

Pause is stored as `paused = true` in `nei_overrides.lua` and survives restarts.
Quantities, fluid identity and refill interval are retained, including when
editing a paused entry. A live Resume preserves an active refill toward Target;
after a process restart the usual below-Low activation rule applies. You can also
set `paused = true` in a config entry, subject to NEI override precedence.

Client 1.3.0 requests multiple entries per screen reply, bounded by the screen
size, 64 entries and 4,096 characters. A representative 23-entry list uses one
exchange at 80x25 instead of 24; at 50x16 it uses two. These are protocol counts,
not measured real-server load times. Batches retain a frozen snapshot, nonce,
offset and checksum validation. Only a complete transfer becomes editable.

The manager retains selection after refresh, supports mouse-wheel paging, saves
the screen UUID, reports load time and offers Cancel during sync. Closing or
cancelling releases the overlay where delivery succeeds, with timeout fallback.
Header/log updates no longer overwrite active replies. New replies update only
their occupied screen lines; the client stops scanning at the frame terminator.

For batched listing, use a 1.3.0+ client JAR and the updated OC scripts; reboot
OC after updating scripts. The fast path
uses `LM4|Q|nonce|screen|offset`; a 1.2.0 receiver still works through the slower
LM3 fallback. Updated scripts also retain LM1/LM2/LM3 compatibility for old clients.
See [installation and testing](client/INSTALLATION-1.3.1.md) and the
[measured call counts](client/VERIFICATION-1.3.0.md).

Removal persists `false` in nei_overrides.lua, masking a base config entry as
well as removing an NEI-added one. Adding the same name again re-enables it.
Quantity edits preserve existing fluid identity and refill timing. Legacy
entries remain visible; editing them requires selecting an explicit Target.

Clipboard list requests return a frozen snapshot via
OC's existing synchronized screen text. The dashboard briefly displays encoded
reply frames during sync; nonce, index and checksum validation prevent accepting
stale or partial frames. Sessions expire after five seconds without a request.
No new server mod or external service is needed. Keep Maintainer running and
use the active GPU's screen UUID. Open the screen once before syncing from NEI.

This version has automated protocol, binary compatibility and mocked OpenOS/AE2
tests; live gameplay testing of the new GUI and screen-sync path remains needed.

The receiver explicitly flushes staged overrides before closing them. OpenOS
may return nil with no error from a successful close, which must not be treated
as a save failure. The same fix applies to the installer's settings refresh.
Regression tests can use the unmodified OpenOS buffering code from your OC JAR:

```sh
python tests/extract-openos.py /path/to/OpenComputers-1.12.64-GTNH.jar /tmp/openos-lib
lua tests/nei-openos-io.lua /tmp/openos-lib
```

