# Using the manager and dashboard

[Overview](../README.md) - [Installation](INSTALLATION.md) - [Configuration](CONFIGURATION.md)

## Default client shortcuts

| Context | Shortcut | Result |
| --- | --- | --- |
| Normal gameplay | Ctrl+M | Manage existing entries |
| Inventory/NEI, hovering an item | Ctrl+M | That label's entry editor |
| Inventory/NEI, no hovered item | Ctrl+M | Manager |
| Inventory/NEI, with or without an item | Ctrl+Shift+M | Manager |

Either Ctrl/Shift key works with the defaults. Release the bound key and all
Ctrl/Alt/Shift keys to open the screen. Holding the
shortcut does not repeatedly open it. Chat, OC terminals and other text-entry
screens retain their shortcuts; close them first. Changing screens/worlds
before release cancels a pending open.

## Changing shortcuts

Client 1.4.0 adds a **NEI Level Maintainer** category to Minecraft's
**Options -> Controls**:

- **Editor or manager shortcut**: context-sensitive editor/manager action;
  default M with CTRL modifier.
- **Open manager shortcut**: always the manager, including over an NEI item;
  default unbound with NONE modifier. Assign an unused keyboard key to enable it.

Controls changes the primary keys. To change the required modifiers, open the
manager and click **Shortcuts...**. Click a key button and press the new key;
Escape while capturing unbinds it. Click its modifier button to cycle
NONE, CTRL, ALT, SHIFT. Choose a regular keyboard key and set modifiers separately;
modifier-only and mouse bindings are not supported. Done saves changes immediately.
The Minecraft Controls button opens the standard controls menu.

For conflicts with Matter Manipulator's Ctrl modifier and a universal terminal
on M:

1. In Options -> Controls, bind Open manager shortcut to an unused key such as F6.
2. Press/release that key without modifiers, then click Shortcuts.
3. Change Context key to an unused key such as N and its modifier to NONE, or
   unbind it if only the dedicated manager shortcut is needed. Keep Manager on
   the chosen key with modifier NONE. Click Done.

After moving/unbinding the context key, M remains available to the terminal and
Ctrl remains available to other tools. Pick keys that are actually unused in
your pack; the addon cannot cancel another mod's use of an identical binding.
The vanilla conflict display compares primary keys, not our separate modifiers.

With NONE, holding Ctrl or Alt prevents activation. With CTRL/ALT, adding Shift
selects the manager instead of a hovered item. With SHIFT as the context modifier,
Shift activates the editor normally; use the independent manager binding for an
always-manager action. A dedicated manager binding takes precedence if both
configured shortcuts match. Text-entry screens retain their own keys.

Primary keys are saved in Minecraft's options.txt. Modifiers are stored in
config/nei-level-maintainer-hotkeys.properties, separate from the UUID/numeric
preferences file. To edit modifiers manually, close Minecraft and use uppercase:

```properties
contextModifier=NONE
managerModifier=NONE
```

Restart after manually editing the file. GUI changes take effect immediately.
Defaults remain Ctrl+M / Ctrl+Shift+M unless you change them; this client-only
update needs no Lua update and preserves the low-load script settings.

## Add, edit, pause and remove

Enter the active OC screen UUID, then Refresh. A saved address is reused and
refresh starts on open. Wait for the full listing. Filter searches names,
item/fluid kinds and paused entries. Scroll or Prev/Next to page.

- Add opens manual name entry. Hovering an NEI item prefills its display label.
- Select a row and Edit to load actual saved quantities. Existing names are fixed;
  the Item/Fluid button can change sections, masking the previous section entry.
- Low, Target and Batch accept whole numbers from 0 to 10^12; Low <= Target,
  Batch >= 1. Hover their labels/fields for explanations.
- Tab/Shift+Tab move focus. Selection replacement, top-row digits, numpad,
  Backspace/Delete and clipboard paste are supported.
- Save to OC submits an update. Submitted is not a server acknowledgement.
  Refresh and inspect the values, or check OC for Updated.
- Pause preserves the entry, shown purple, while suppressing new work. Resume
  re-enables it. Already submitted AE2 jobs continue.
- Remove requires a second confirmation and survives restart, even for a base
  config entry. Adding the same label/type again re-enables it.
- Back/Escape leaves without saving unsent changes.

A hover editor starts with saved local numeric defaults, not necessarily an
existing entry's values. Use Manage -> Edit to load actual saved values.
Quantity edits preserve pause, fluidName and refillInterval metadata. Legacy
entries without Target remain visible; editing requires choosing a Target.

Pause is saved in nei_overrides.lua. Live Resume preserves active refill state;
after a program restart the normal below-Low trigger applies.

## Listing and OC screen text

Refresh reads effective configuration, not the entire ME inventory. Encoded
replies briefly appear on the OC screen and travel through its existing client
buffer. Open the physical screen once before managing remotely. Only a complete,
checksum-validated listing becomes editable. Refresh retains the selection where
possible and reports load time.

Cancel/close ends the overlay when delivered; it also expires five seconds after
the last request, returning to normal on redraw. One client can sync with a
computer at a time. Another request or config mutation can invalidate a snapshot.

## Dashboard

Stock is the last checked quantity, not a live count. It is not read during a
craft, retry wait, no-CPU wait, pause, or stocked cooldown. Gray means an older
observation. A dash means no observation or a continuous entry without threshold.
Partial production may not appear until the craft finishes and stock is checked.

Want shows Low while idle and Target during refill. Batch is a configured request
cap, not progress. CPU counts are snapshots; skipped passes label them (cached),
and a list that has never needed a query shows CPUs: not polled.

| Status | Meaning |
| --- | --- |
| waiting | No result yet |
| stocked | No request needed under the current threshold/refill state |
| requested | AE2 accepted a request |
| crafting | CPU snapshot reports the label as an active output |
| waiting for CPU | No eligible idle CPU in the snapshot |
| failed | Request failed; inspect Recent for reason/retry |
| not craftable | No matching craftable found |
| error | Entry processing raised an error |
| paused | Configured but no new work requested |

Problem rows come first, then alphabetical entries. fit intentionally selects
large text; a GPU upgrade does not force smaller text in fit mode. Use fixed or
columns to retain resolution. Overflow uses pages. showRecent=false frees room.

## OC keyboard and recovery

Keys work during waits between passes and startup waits. Long AE2 calculations
can delay input handling.

| Key | Action |
| --- | --- |
| E / S | Edit config / settings; save Ctrl+S, close Ctrl+W |
| R | Check saved changes and retry a failed dashboard |
| Q | Stop Maintainer |
| Page Up/Down or Up/Down | Dashboard pages |
| Ctrl+Alt+C | Interrupt |

Ordinary passes rotate their starting entry for CPU fairness. Unexpected errors
normally restart after retryDelay, at least five seconds. A broken startup config
waits for repair. Power loss turns the computer off; optional auto-start and
wake-on-redstone can boot it again when power is available.
