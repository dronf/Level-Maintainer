# Configuration reference

[Overview](../README.md) - [Usage](USAGE.md) - [Performance](PERFORMANCE.md)

## Files and precedence

| File | Purpose |
| --- | --- |
| config.lua | Base items/fluids; returns a cfg table |
| settings.lua | Timing, CPU, logging and display settings; returns a settings table |
| nei_overrides.lua | NEI changes, pause states and removal markers; overrides the base config |

An override replaces the base entry in its items/fluids section. A false marker
masks the base entry. Removing an override can restore a base value; use the
manager's Remove action to stop a base entry persistently. Back up all three files.

Press E to edit config or S to edit settings while Maintainer waits. Save with
Ctrl+S and close with Ctrl+W; Maintainer reloads after the editor closes. R checks
saved-file timestamps. An invalid reload keeps the last working configuration.
Starting the program reads files fresh. R does not force a craftable-cache reset.

## Low / Target / Batch

```lua
local cfg = {items = {}, fluids = {}}
cfg.items["Microprocessor"] = {low = 10, target = 64, batch = 16}
return cfg
```

- Low starts an idle refill only when observed stock is **strictly below** Low.
- Target stops an active refill when observed stock reaches Target.
- Batch caps each request: `min(batch, ceil(target - stock))`.

At 9 with no consumption: 9 -> 25 -> 41 -> 57 -> 64. At exactly 10 an idle entry
does not start. A newly started program with stock 40 waits, rather than filling
every partially filled target. Low 0 never triggers from nonnegative stock.
Output multiples and simultaneous producers may overshoot Target.

Active refill state survives unchanged reloads and live Pause/Resume. Restarting,
or changing production settings on an entry, resets that state. Stock between
Low and Target then waits for a below-Low check.

Items use individual counts, not stacks. Native fluids use mB: 1,000 = one bucket.
Larger batches reduce repeated AE2 calculations, subject to ingredients, machine
capacity and crafting CPU storage.

## Legacy thresholds and continuous production

```lua
cfg.items["Osmium Dust"] = {10000, 1000} -- fixed batch while stock < 10,000
cfg.items["Blank Pattern"] = {nil, 64}  -- continuously request batches of 64
```

A legacy threshold has no separate Target and requests the fixed batch, including
possible overshoot. Literal {0, 64} is not continuous: stock must be below zero.
Use {nil, batch} in Lua. Current jobs, CPU availability and retry waits still apply.

The NEI editor requires Low, Target and Batch, so it cannot directly create
nil-threshold continuous entries. Legacy entries appear as legacy; editing one
requires choosing a Target. The browser editor's simple mode exports blank/zero
Maintain as nil; its Target mode treats Low 0 literally.

For recycling loops, continuous Lua entries avoid intentionally unreachable
targets. Test cyclic AE2 recipes with small batches and enough circulating input.
Encode only guaranteed recipe outputs; a chance byproduct must not be promised
as a guaranteed output.

## Items, fluids and labels

```lua
local cfg = {items = {}, fluids = {}}
cfg.items["Microprocessor"] = {low = 10, target = 64, batch = 16}
cfg.fluids["Ammonia"] = {low = 1000000, target = 1500000, batch = 100000}
cfg.items["drop of Molten SpaceTime"] = {1000000, 1000, "spacetime"}
return cfg
```

Names are exact craftable display labels, including case and punctuation. Use
the label in your own network, not an ore-dictionary name or registry ID. Native
GTNH 2.9 fluids are detected from their output stack; items and native fluids can
appear in either section. The optional fluidName registry override supports old
ae2fc fluid drops and ambiguous fluids. A fluid-drop item and native fluid are
different representations.

The lookup selects the first craftable returned for a label. Duplicate display
names can collide; labels do not select a precise NBT variant or processing
pattern. Keep names unique across sections. Native fluid entries are skipped
when the interface lacks getFluidInNetwork; full native-fluid support targets 2.9.

## Pause and faster active refills

```lua
cfg.items["Osmium Dust"] = {
    low = 10000, target = 20000, batch = 1000,
    refillInterval = 30, paused = true,
}
```

paused=true keeps the entry while suppressing new stock checks and requests.
Submitted jobs continue. A saved NEI override takes precedence over the base pause.

refillInterval is a finite positive number of real seconds, including fractions,
requiring Low and Target. Once refilling activates, this entry gets its own
checks; idle checks stay adaptive. Each deadline starts after the preceding check
finishes, without catch-up bursts. Existing jobs, CPU contention, calculation
time and retryDelay can delay requests. Very short intervals add work.

NEI preserves existing refillInterval/fluidName values but has no controls for
setting them; use Lua or the browser editor.

## Every setting and default

| Setting | Default | Behavior |
| --- | --- | --- |
| sleep | 60 | Seconds waiting after an ordinary pass; execution time is additional |
| headerInterval | 60 | Cosmetic clock/countdown cadence; does not change refill deadlines |
| thresholdIntervals | {300,600,900,1800,3600} | Stocked delays for stock/Low ratios <1.25, <2, <5, <10, otherwise |
| retryDelay | 300 | Failed-request retry seconds; 0 retries next cycle; unexpected-error restart waits at least 5 seconds |
| requireFreeCpu | true | Gate calculations on idle CPU snapshot |
| cpuName | nil | Exact CPU name for requests; ensure it exists and fits the job; nil lets AE2 choose |
| cacheDuration | 3600 | Craftable and negative-lookup cache lifetime; restart to discover changed patterns immediately |
| pollInterval | 5 | Seconds between checks while AE2 calculates a request; longer waits delay subsequent entries too |
| logSkips | false | Log stocked, crafting, no-CPU and retry skips |
| logRepeats | false | Repeat unchanged statuses in table Recent; log mode remains deduplicated |
| utcOffset | 0 | Hours added to UTC; adjust manually for daylight saving |
| display | "table" | Status table; "log" selects scrolling log |
| showRecent | true | Show recent messages; false gives entries more screen space |
| layout | "fit" | Layout/resolution mode, below |
| cpuDisplay | "free" | Idle CPU count; "busy" shows occupied count |
| reloadCheck | 0 | External file-change polling seconds; zero disables |

Stock deadlines are serviced on ordinary passes. Sudden withdrawals can wait
the stock interval plus a cycle/pass before detection. Five zero thresholdIntervals
values check every cycle. Low 0 uses the final stock-delay tier. CPU queries are
skipped completely when no entry is due.

Layouts: fit chooses the largest text that fits; wide keeps wide name columns on
tall screens; tall uses narrow columns/short statuses; fixed retains resolution
with one table; columns retains resolution and uses side-by-side tables where
possible. Automatic layout restores the old resolution on exit.

## Browser configuration editor

Follow the [complete browser editor walkthrough](BROWSER-EDITOR.md) for a worked
example, output modes, transfer to OC, imports/backups, sharing, and the
difference between disabled browser rows and persistent NEI pause/overrides.

Open [index.html](index.html) in a downloaded repository with config.js beside it.
Named lists live in browser storage; export backups before clearing site data.
The editor supports imports, named/positional entries, targets, refill intervals,
items/fluids, disabled lines, backups and abbreviated numbers (k, m, g/b, t),
exporting plain Lua numbers. NEI fields accept plain whole numbers.

Copy-next-part respects OC's 1,024-character paste limit. Edit with E, replace
the base config, paste parts in order, save and close. Unsupported imports are
rejected as a whole; imported Lua is not executed in the browser. Share links
need HTTP(S); use backup files in local-file mode. Updating base config through
the browser does not remove existing NEI overrides on the OC computer.
