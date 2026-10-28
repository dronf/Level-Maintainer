# NEI Level Maintainer client 1.4.0

The client-only Minecraft 1.7.10 addon for the Level Maintainer OC program.

[Download built JAR](https://github.com/dronf/Level-Maintainer/releases/download/nei-level-maintainer-1.4.0/nei-level-maintainer-1.4.0.jar)
- [Full project guide](../../README.md)
- [Install/update](../../docs/INSTALLATION.md)
- [Controls and manager](../../docs/USAGE.md)
- [Build and tests](../../docs/DEVELOPMENT.md)
- [Current verification](VERIFICATION.md)

Close Minecraft and replace the previous addon in Prism's .minecraft/mods folder;
keep exactly one version. Install this JAR on the client only. Keep the normal
GTNH NEI/OpenComputers dependencies installed.

Default Ctrl+M opens the manager in gameplay and the hovered-item editor in
NEI. Ctrl+Shift+M selects the manager. These shortcuts are now configurable.

In Minecraft Options -> Controls -> NEI Level Maintainer, set Open manager
shortcut to an unused keyboard key (it starts unbound and uses modifier NONE).
Open the manager and click Shortcuts to change both keys and NONE/CTRL/ALT/SHIFT
modifiers. Set the context key to N and modifier NONE, for example, to free both
Ctrl and M for other mods. Done saves immediately; no restart is required.
See [shortcut settings](../../docs/USAGE.md#changing-shortcuts).

The manager reads actual OC configuration and supports search, paging, Add,
Edit, Pause/Resume and confirmed Remove. Keep Maintainer running, enter the
active GPU's screen UUID, open that OC screen once to synchronize its buffer,
and remain within normal interaction range. A submitted update is not an
acknowledgement: refresh or check OC.

Client 1.4.0 is required for configurable shortcuts. Existing Lua 1.3.4 scripts
already supply the low-load defaults and need no update for this feature.
Existing saved timings are preserved. Input, hover help,
pause controls and LM4/legacy listing compatibility are retained. No networking
crash fix is included.

The build uses JDK 17 --release 8 against actual GTNH 2.9 RC2 SRG Minecraft,
Forge 10.13.4.1614, NEI 2.8.155-GTNH and OC 1.12.64-GTNH dependencies. Run
tools/build.ps1 and tools/verify.ps1 with your local pack paths as shown in the
development guide. Tests use real Minecraft classes with synthetic input and
simulated OC/AE2 responses; full pack gameplay and TPS remain separate checks.
