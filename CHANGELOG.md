# Release history

[Overview](README.md) - [Downloads](https://github.com/dronf/Level-Maintainer/releases)

Versioned installation/verification notes are historical records for their
named versions. Use the current guides for present-day commands and behavior.

## 1.3.4 - 2026-10-25

- Default to a 60-second ordinary cycle and header, 300-second retry delay,
  3,600-second craftable cache and five-second computation polling.
- Stocked checks default to 300/600/900/1,800/3,600 seconds by stock ratio.
- Disable skip logging by default; retain free-CPU gating and disabled live reload.
- Fresh config starts empty, with only commented opt-in examples.
- Synchronize shipped defaults, runtime fallbacks and invalid-interval fallbacks.
- Add bold setup guidance explaining deliberately low polling frequency and slow
  replenishment. Document adopting the profile without overwriting user settings.
- Preserve explicit old/custom timings and fast per-entry refill opt-ins. No
  clipboard or Java client behavior change; version-matched JAR included.

## 1.3.3 - 2026-10-24

- Reorganize full project documentation: installation, operation, configuration,
  performance, troubleshooting, protocol and development/release instructions.
- Document all settings, exact threshold semantics, continuous Lua entries,
  override precedence, pause persistence, units, limitations and recovery.
- Include a freshly built client JAR, matching OC bundle, complete source,
  verification, installation guide and SHA-256 checksums in the release.
- Add a reproducible release packager. Runtime behavior remains the same as 1.3.2;
  Java version metadata/build output moves to 1.3.3.
- No multiplayer server-list networking crash patch is included.

## 1.3.2

Skip CPU/job queries when no entry is due; show cached/unknown CPU counts.
Validate downloaded Lua, retain originals through replacement, roll back reported
installation failures, preserve recovery backups, and support a version argument.
Add Low/Target/Batch hover help.
[Verification](client/VERIFICATION-1.3.2.md).

## 1.3.1

Ctrl+M opens the manager in normal gameplay, with either Ctrl key, release
handling, repeat suppression and cancellation on screen/world changes.
[Verification](client/VERIFICATION-1.3.1.md).

## 1.3.0

Batch configuration listing over synchronized OC screen replies; preserve
selection, show elapsed load time, support cancellation and mouse-wheel paging,
and protect replies from cosmetic redraws. Maintain slower receiver fallback.
[Verification](client/VERIFICATION-1.3.0.md).

## 1.2.0

Persistent per-entry Pause/Resume in the manager, with purple status on OC.
Preserve quantities, fluid identity and refill timing.
[Verification](client/VERIFICATION-1.2.0.md).

## Earlier work

The 1.1.x clients added manager listing, editing/removal and item/fluid conversion;
fixed OpenOS nil-close handling, numeric editing, repeated digits, wide-button
rendering and NEI/lwjgl3ify input isolation.
[1.1.5 verification](client/VERIFICATION-1.1.5.md).

The Lua fork added targeted/cached lookups, native fluids, hysteresis, adaptive
stock checks, retry/error recovery, timed refills, settings preservation,
reduced clock/display work and the offline browser editor. Additional CPU
rescans were reverted to reduce load; current releases retain that decision.

See git history and the versioned notes for individual changes. Older local
build numbers without a published release tag should not be treated as
downloadable GitHub releases.
