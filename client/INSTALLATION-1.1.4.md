# NEI Level Maintainer 1.1.4

Close Minecraft. Remove the older NEI Level Maintainer JAR from the Prism instance's mods folder, add nei-level-maintainer-1.1.4.jar, and restart Minecraft. Keep exactly one copy of the addon.

This is a client-only correction to duplicate numeric input in 1.1.3. No additional Lua update is needed if the OC receiver was already updated for 1.1.3. The receiver upgrade described in INSTALLATION-1.1.3.md is still required for Item/Fluid conversion.

lwjgl3ify 3.0.37 emits both a physical keypress and a separate character-only event (key=0). Version 1.1.3 accepted both. Numeric fields now accept physical digits and ignore the duplicate character-only event. There is no timing-based suppression; two physical presses and held-key repeats remain valid.

Test: In both Ctrl+M Add and Manage/Edit, click each numeric field and type 123 using the top row, then the keypad. Each should show 123. Clear using Backspace/Delete. Press the same digit twice: both should appear. Hold a digit to check repeat behavior. Save and check OC's values.

Validation: reproduced the doubled digit with paired events before the fix. All 71 real text-field checks, 59 editor/render checks and 38 protocol/reply checks pass after the fix. Pair-event tests cover every digit on the top row and keypad, and repeated physical presses. Add/Edit tests now send both event types. Compiled against actual GTNH 2.9 RC2 dependencies; verified 12 Java 8 classes and 1,031 bytecode references. Inspected the installed lwjgl3ify addCharEvent/addSdlKeyEvent bytecode. Tests are headless and do not exercise a physical keyboard in the running modpack; in-game confirmation remains outstanding.
