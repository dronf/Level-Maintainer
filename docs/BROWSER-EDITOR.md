# Browser configuration editor

[Overview](../README.md) - [Configuration](CONFIGURATION.md) - [NEI manager](USAGE.md)

The browser editor builds **config.lua**, the maintainer's base item/fluid list.
It runs locally and does not connect to Minecraft, read your ME network, or send
changes to OC. You must export the result and install it on the OC computer.
It is separate from the Ctrl+M NEI manager, which edits the running computer.

## Open it and keep your data

1. Download and extract the project source using **Code > Download ZIP** on
   [the repository](https://github.com/dronf/Level-Maintainer), or use a source
   or offline documentation ZIP from
   [the releases page](https://github.com/dronf/Level-Maintainer/releases).
2. Open `docs/index.html` in a modern browser. Keep `docs/config.js` beside it;
   copying only the HTML file is not sufficient.
3. Use the same browser/profile/location to return to your saved lists.
   Private browsing, blocked site data, clearing storage, changing browsers,
   or moving between local and hosted versions can make old lists unavailable.
4. Click **Export backup** to keep a portable JSON copy. A config.lua download
   is the current computer configuration; a backup contains all browser lists.

The editor warns when browser storage cannot be saved. In that case export
before closing. Local files work without a server. Share links require an
HTTP(S)-hosted copy; this project does not require you to host one.

## Worked example: maintain microprocessors

1. Click **New list**, enter `Main base`, and select it under **Current list**.
   A browser list name is just an organizational label, not an AE2 network address.
2. Enter these fields:

   | Field | Value |
   | --- | --- |
   | Name | `Microprocessor` |
   | Maintain / Low | `10` |
   | Batch Amount | `16` |
   | Refill target | `64` |
   | Refill interval | Leave blank |
   | Entry type | Item / auto-detected fluid |
   | Fluid registry override | Leave blank |

3. Click **Add (Enter)**. The row appears in Entries and the output updates.
   Use the exact craftable display name in your own pack; the example label
   must actually have a visible pattern on that OC computer's ME network.
4. Select **Whole config.lua**. The generated entry is:

   ```lua
   local cfg = {}
   cfg["items"] = {
       ["Microprocessor"] = {low = 10, target = 64, batch = 16},
   }
   cfg["fluids"] = {
   }
   return cfg
   ```

5. Follow [Transfer to OpenComputers](#transfer-to-opencomputers). Nothing in
   Minecraft changes just because a row was added to the browser.

At stock 9, the intended refill is 9 -> 25 -> 41 -> 57 -> 64, with no consumption
or extra production. At exactly 10 an idle entry does not start. With Target
present, Low 0 never starts from nonnegative stock.

**The program's default polling frequency is deliberately very low.** On 1.3.4,
ordinary maintenance is once per minute and stocked checks are 5-60 minutes
apart. Leave Refill interval blank for that normal schedule. Short active-refill
intervals increase CPU/job checks; see [performance settings](PERFORMANCE.md).

## Field reference

| Field | Meaning |
| --- | --- |
| Name | Exact craftable display label; quotes around a pasted name are optional |
| Maintain / Low | Trigger threshold; behavior depends on whether Target is present |
| Batch Amount | Positive whole-number request size; capped by missing stock in Target mode |
| Refill target | Optional upper stock level; must be at least Low |
| Refill interval | Optional positive real seconds, such as 30 or 0.5; requires Target and applies only while refilling |
| Entry type | Item / auto-detected fluid writes cfg.items; Fluid writes cfg.fluids |
| Fluid registry override | Optional internal fluid name for old fluid drops or disambiguation, not the display label |

Items use individual units, not stacks. Native fluids use mB: 1,000 mB = one
bucket. For a native fluid, choose Fluid and use its exact craftable label.
Usually leave the registry override blank; OC detects it from the craftable.
For old ae2fc drop items, use the actual drop label and appropriate registry
name. Do not put an ore-dictionary name such as ingotHotTitanium in Name unless
that is literally the craftable display label.

### Threshold mode versus continuous production

| Target | Maintain / Low | Export behavior |
| --- | --- | --- |
| Blank | Positive number | Legacy threshold: request a fixed batch whenever stock is below Maintain |
| Blank | Blank or 0 | Continuous: export a nil threshold and keep requesting batches, subject to jobs/CPUs/retries |
| Present | Nonnegative number | Start below Low; continue until Target, capping the final request |

The browser intentionally normalizes simple-mode zero to nil. That differs
from hand-written Lua `{0, 64}`, whose literal zero threshold never triggers
from nonnegative stock. Do not use a browser round trip to preserve that special
legacy-zero meaning. Use Target mode if you need a literal Low of zero.

Numeric inputs support k (thousand), m (million), g/b (billion) and t (trillion).
For example, 250k = 250000, 1.5m = 1500000, and 1,024 = 1024. Expanded values
must be whole safe integers; exports contain plain numbers, never Lua `10k`
literals. Refill interval is seconds rather than an amount abbreviation.
The NEI numeric editor separately caps quantities at 10^12; keep within that
range if you intend to edit the entries through NEI later.

## Manage lists and entries

- **New list** creates an independent list; **Current list** selects which one
  is being edited/exported. These are not automatically combined.
- **Rename** changes the browser label only. **Delete list** asks for confirmation;
  export a backup first. Deleting the last list leaves a new empty list.
- Click a row to edit it and **Update (Enter)** to save. **New entry (Esc)** clears
  the form without deleting the saved row. Unsaved form changes are not in output.
- Adding the same name and entry type again updates that existing row rather
  than adding a duplicate. Different item/fluid sections are distinct entries;
  duplicate display labels can still collide in the running maintainer.
- The row's delete button removes it from this browser list after confirmation.
  It does not send a removal to Minecraft.
- **Copy line** generates one Lua entry from the current form. It does not add
  or update the saved row; use the full preview for the list's enabled states.

## Output modes and buttons

| Control | What it produces |
| --- | --- |
| Whole config.lua | Complete file with local cfg, both sections and return cfg; use for full replacement |
| Sections only | Both cfg.items/cfg.fluids assignments without the surrounding local/return; use inside an existing file |
| Copy all | Current selected output mode, copied as one clipboard payload |
| Copy next part | Current selected output in consecutive chunks of up to 1,000 characters |
| Download config.lua | Always a complete file, even when Sections only is selected |

**Sections only replaces section assignments, not merely individual entries.**
When merging manually, combine the desired entries in one items block and one
fluids block. Appending another cfg.items assignment can discard earlier items.
Keep exactly one appropriate final `return cfg` and a defined local cfg table.

## Transfer to OpenComputers

1. Back up the OC computer's config.lua, settings.lua and nei_overrides.lua if
   present. Export a browser backup too. Only config.lua is being replaced here.
2. Choose **Whole config.lua** and finish editing the browser list.
3. While Maintainer is waiting, press **E** on its OC screen to open config.lua.
   Replace the entire old file contents; do not leave old blocks or returns behind.
4. For output within the OC paste limit, use Copy all and paste normally.
   For a longer file, use **Copy next part** and paste each part in order.
   The page uses 1,000-character chunks, below the 1,024-character OC limit.
5. Keep the cursor immediately after the previous part. A chunk may end in the
   middle of a Lua line, so do not add separators/newlines between parts. The
   original newlines are already included. Stop after the last-part message;
   the next click wraps back to part 1. Changing output resets the part counter.
6. Save with **Ctrl+S**, close with **Ctrl+W**, and inspect OC for config reload
   errors. Refresh the NEI manager to inspect the effective configuration.

A downloaded config.lua can instead be copied to that installation directory
if you have filesystem access to the OC disk. Stop Maintainer before external
replacement, then restart, or use the normal saved-file reload mechanism.
Download alone cannot install a file into a remote multiplayer computer.

## Import existing Lua or backups

**Import lines...** accepts supported config entries, section assignments or a
whole supported config.lua into the current list. It adds new names and updates
existing names of the same entry type; it does not replace all other list rows.
Commented-out entries import as disabled. Duplicate entries or unsupported
syntax in one pasted input reject that entire import without changing the list.

Supported entry fields are positional threshold/batch/optional fluid name, or
named low/target/batch/optional fluidName/refillInterval. Multiline entries,
double-quoted labels and escaped quotes/backslashes are supported. The parser
does not execute Lua and does not accept arbitrary expressions, functions,
mixed positional/named fields or unrelated configuration fields.

**Do not import nei_overrides.lua as a normal config.** Its removal markers
(`false`) and `paused` fields are not supported by this editor's Lua importer.
An entry with `paused = true` or `paused = false` is rejected, not preserved.
Keep that file separately backed up and manage its state through NEI or careful
manual editing. Imports are not a complete backup of the running computer.

**Import backup or configs.json...** reads JSON, not Lua. It accepts this editor's
backup files or the old PowerShell ConfigList configs.json. Imported backup lists
are added as new lists; existing lists are retained and conflicting list names
get numbered suffixes. Export backup saves every browser list, including targets,
refill intervals, fluid types/overrides and browser enabled states.

## Disabled rows, NEI pause and overrides

These are different operations:

| Action | Effect after applying changes |
| --- | --- |
| Untick browser On | Exports a commented base-config entry; it remains in the browser list |
| Delete browser row | Omits that base entry from future exports |
| NEI Pause | Saves paused=true in an override; keeps the entry and its state visible |
| NEI Remove | Saves a false override marker; masks a base entry as well |

**Unticking On does not pause an existing NEI override.** Browser changes only
alter the exported base config; overrides still win. A browser update to an
overridden item can therefore appear ineffective. A false removal marker can
also keep a newly exported base entry hidden. Editing config.lua never clears
those markers or pause values automatically.

Choose one owner for each entry: use NEI to manage its live override, or back
up and remove only that matching override to restore browser/base ownership.
Removing an override can re-enable a base entry. Do not delete the whole override
file just to change one item. Use NEI Pause to temporarily stop a live entry
while keeping it listed; submitted AE2 jobs still continue.

## Sharing and common problems

Copy share link works only on an HTTP(S) editor. It embeds the current list in
the URL; opening it offers **Add as a new list** or **Ignore**. It does not
automatically apply anything to OC. Use Export backup/Import backup for local
files or offline transfer. Anyone with the link can read the included list.

If controls do not work, confirm config.js is present. If copying is blocked,
use the preview or download. If the browser reports unavailable storage, export
before closing. If an import fails, correct the indicated unsupported entry;
do not assume part of it was imported. If Minecraft does not change, check that
you installed the output on the intended OC disk and inspect NEI overrides.
The broader [troubleshooting guide](TROUBLESHOOTING.md) covers patterns, sampled
stock, slow default timing and CPU availability.
