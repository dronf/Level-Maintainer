# NEI Level Maintainer 1.4.0 verification - 2026-10-28

Artifact: nei-level-maintainer-1.4.0.jar
SHA-256: `4a960ca0863a803d4aa0bc1b8953bc86112aa0d6accf7f1c450f4080915e617a`

## Change

Register two vanilla Minecraft Controls bindings: context-sensitive editor/manager
(default M + CTRL), and independent manager (default unbound + NONE). A manager
Shortcuts screen edits keyboard keys and NONE/CTRL/ALT/SHIFT modifiers. GameSettings
saves primary keys to options.txt; modifiers use a separate properties file.
Both FML gameplay and NEI container callbacks use these bindings and modifiers.
Default Shift override and release/repeat/screen/world cancellation remain.
Mouse or modifier-only primary bindings do not activate the addon.

This changes only the client addon. Existing 1.3.4 Lua scripts and saved polling
values remain compatible; no clipboard protocol or AE2 scheduling change.

## Passed validation

- Built using JDK 17 --release 8 and the actual installed GTNH 2.9 RC2
  Minecraft 1.7.10 SRG, Forge 10.13.4.1614, NEI 2.8.155-GTNH and OC
  1.12.64-GTNH binaries. All 19 Java 8 classes / 1,605 member references pass
  the binary verifier, production SRG GUI checks and -Xverify:all entrypoint loading.
- 61 shortcut checks exercise actual FML/NEI callbacks with synthetic LWJGL
  state: old defaults, custom keys, rejection of the old M chord after rebinding,
  NONE with unwanted Ctrl, both Alt keys, Shift semantics, independent manager
  in/out of inventory, held/repeated/release events, cancellation, disabled and
  unsupported keys, idempotent Controls registration, saved modifier round trips,
  invalid-value fallback, key capture, unbinding and modifier controls.
- Existing encoder (20), reply parser (38), real Minecraft field input (74),
  editor/button checks (77, or 80 with installed lwjgl3ify 3.0.37), shared-buffer
  isolation, pause controls (12), and listing lifecycle checks (23) all pass.
- Documentation links/encoding, archive CRCs, Java namespace/metadata and
  release checksums are checked before publication.

## Limits and acceptance

Tests use real Minecraft/LWJGL classes with synthetic input, a GameSettings save
recorder, and a temporary properties file. They do not run the full pack, reproduce
Matter Manipulator/universal-terminal conflicts with physical input, or validate
actual options.txt across a full game restart. Vanilla Controls registration uses
the same GameSettings array operation as the installed Forge 1.7.10 ClientRegistry;
Forge reloads options after initialization. Test in game after installing:

1. Bind the independent manager key in Options -> Controls, for example unused F6.
2. Open it and choose Shortcuts; set context to an unused N with modifier NONE,
   or unbind context entirely. Keep the manager key modifier NONE. Save with Done.
3. Verify M opens the universal terminal and Ctrl retains Matter Manipulator use;
   check the new context/manager keys in gameplay and NEI, including extra Shift.
4. Test text entry, then restart Minecraft and confirm keys and modifiers persisted.
5. Confirm existing entries, pause state, listing and crafting still work.

See [usage](../../docs/USAGE.md#changing-shortcuts),
[installation](../../docs/INSTALLATION.md), and [build instructions](../../docs/DEVELOPMENT.md).
