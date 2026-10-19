# Verification: client 1.1.5

Compiled with Java 17 --release 8 against the real GTNH 2.9 RC2 Minecraft/Forge and installed NEI/OC JARs. Verified 14 Java 8 classes and 1,092 bytecode member references.

Passed 74 real GuiTextField checks, 75 editor/render checks without lwjgl3ify and the same suite extended to 78 checks with its actual shared text buffer. Existing 20 encoder and 18 reply checks also pass. Tests cover paired physical/character events, top-row/keypad digits, deletion, hover/manual creation and managed edit, NEI focus release, stale-container forwarding, unchanged search text and closing-field cleanup.

A dedicated regression populates the real installed lwjgl3ify 3.0.37 TextFieldHandler.textBuffer and sends numeric events. It fails using 1.1.4's compiled FieldFocus class with 'Numeric text remains queued for NEI: 123', and passes using 1.1.5.

The font and drawing are stubbed for headless tests. The installed lwjgl3ify buffer is real, but the full modpack mixin transformation pipeline and physical keyboard are not exercised. In-game confirmation of the intermittent editing issue remains outstanding. No Lua changes were made for this client release.
