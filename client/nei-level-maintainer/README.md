# NEI Level Maintainer client 1.3.3

The client-only Minecraft 1.7.10 addon for the Level Maintainer OC program.

[Download built JAR](https://github.com/dronf/Level-Maintainer/releases/download/nei-level-maintainer-1.3.3/nei-level-maintainer-1.3.3.jar)
- [Full project guide](../../README.md)
- [Install/update](../../docs/INSTALLATION.md)
- [Controls and manager](../../docs/USAGE.md)
- [Build and tests](../../docs/DEVELOPMENT.md)
- [Current verification](VERIFICATION.md)

Close Minecraft and replace the previous addon in Prism's .minecraft/mods folder;
keep exactly one version. Install this JAR on the client only. Keep the normal
GTNH NEI/OpenComputers dependencies installed.

Ctrl+M in normal gameplay opens the manager. Over an NEI item it opens the entry
editor; Ctrl+Shift+M always selects the manager in an inventory/NEI screen.
Either Ctrl key works; release the shortcut. Existing text-entry screens retain
their own input.

The manager reads actual OC configuration and supports search, paging, Add,
Edit, Pause/Resume and confirmed Remove. Keep Maintainer running, enter the
active GPU's screen UUID, open that OC screen once to synchronize its buffer,
and remain within normal interaction range. A submitted update is not an
acknowledgement: refresh or check OC.

This release has the same runtime behavior as 1.3.2. Updated documentation,
build metadata and release packaging identify 1.3.3. Input, hotkeys, hover help,
pause controls and LM4/legacy listing compatibility are retained. No networking
crash fix is included.

The build uses JDK 17 --release 8 against actual GTNH 2.9 RC2 SRG Minecraft,
Forge 10.13.4.1614, NEI 2.8.155-GTNH and OC 1.12.64-GTNH dependencies. Run
tools/build.ps1 and tools/verify.ps1 with your local pack paths as shown in the
development guide. Tests use real Minecraft classes with synthetic input and
simulated OC/AE2 responses; full pack gameplay and TPS remain separate checks.
