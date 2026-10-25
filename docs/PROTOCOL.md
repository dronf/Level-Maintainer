# Clipboard protocol and persistence

[Overview](../README.md) - [Usage](USAGE.md) - [Development](DEVELOPMENT.md)

## Transport and authorization

The client calls OC 1.12.64-GTNH's existing PacketSender clipboard path.
The normal screen interaction permissions/range and OC clipboard length/cooldown
apply. The receiver is a clipboard listener in the running Maintainer process;
no added server mod, socket service or custom client/server channel is required.

Listing replies are ASCII frames drawn on the active GPU-bound screen, read
from OC's existing synchronized client buffer. Nonces/checksums reject stale or
partial replies; they do not create new access permissions or replace OC checks.
Only one listing session exists per running receiver.

## Mutation requests

I/F identify items/fluids sections. These are protocol examples, not Lua commands:

```text
LM1|I|Microprocessor|10|64|16
LM2|D|I|Microprocessor
LM2|P|I|Microprocessor|1
LM2|P|I|Microprocessor|0
LM2|T|I|F|Ammonia|1000000|1500000|100000
```

LM1 adds/updates explicit Low/Target/Batch. D removes, P pauses/resumes, and T
atomically converts a previous section to a new section and updates quantities.
Names must be 1-160 UTF-8 bytes, with no pipes/control characters. Client updates
accept whole numbers 0..10^12, Low <= Target and Batch >= 1.

Updates preserve existing pause, fluid identity and refill interval. Remove
writes false to mask even a base config entry; re-add replaces the marker.
Pause clones the effective entry and changes paused. A conversion masks the old
section. Saved overrides merge over config.lua.

The receiver stages and flushes nei_overrides.lua.tmp before replacement,
accepts OpenOS nil/no-error close success, backs up to .bak, then reloads and
repaints. OC prints Updated/Removed/Paused/Resumed only after successful reload.
Client submission text alone does not acknowledge success.

## Listing requests

```text
LM4|Q|0123456789abcdef|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|0
LM2|END|0123456789abcdef
```

The token is 16 hex characters; the screen is the bound 36-character UUID.
LM4 uses a zero-based row offset and a frozen configuration snapshot. Reissuing
the same offset/token reuses the snapshot; mutations invalidate it.
Batches fit min(screen width * height, 4096) characters and at most 64 records.
A record is:

```text
kind|hex_utf8_name|low|target|batch|refillInterval|paused
```

Optional legacy values are empty fields; paused is 0 or 1. Records are separated
by semicolons. A normal frame body starts LM4R|token|offset|total|count|records.
The receiver appends a separator, eight lowercase hex Adler-32 checksum digits
of the ASCII body, and |END. The client reads to the terminator, validates the
nonce/offset/checksum, and commits entries only after the full transfer.

Errors return an ERR frame. A screen too small for one record must be enlarged.
Session timeout is five seconds since the last request, with normal display
restored on a subsequent draw. Explicit END tries to restore sooner.

## Compatibility and limits

- LM1 remains the original PR #5 add/update form.
- LM2 supplies removal/type conversion/pause/session-end and old listing support.
- LM3 lists one entry per reply and includes pause state.
- LM4 batches the same entry metadata. Clients 1.3.0+ try it first and can fall
  back to the older receiver path; update both sides for the full feature set.
- The client caps accepted listings at 10,000 entries.
- The snapshot omits malformed non-table entries and unsupported names.
- Byte lengths matter for non-ASCII names. Display-label identity is not a registry
  ID or NBT identity, so identical names can collide.
- Native fluid support comes from OC/AE2's stack API, not an added bridge service.

See nei_bridge.lua and ScreenReply.java for the exact implementation; protocol
regressions and cross-language tests are described in the development guide.
