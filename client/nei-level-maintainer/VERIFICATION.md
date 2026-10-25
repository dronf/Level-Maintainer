# NEI Level Maintainer 1.3.4 verification

Built 2026-10-25. JAR: nei-level-maintainer-1.3.4.jar
SHA-256: `c94f706df884f92e46d450fe6a4e5b93599c41d683851ee17280b5359f1815ef`

## Change and scope

Lua defaults now prioritize low server load: sleep/headerInterval=60,
retryDelay=300, cacheDuration=3600, pollInterval=5, stock delays
{300,600,900,1800,3600}, logSkips=false. Existing explicitly saved settings,
legacy cfg.sleep, and per-entry refill opt-ins remain respected. The fresh
config has no active entries. Clipboard and executable Java behavior are unchanged.

## Passed validation

- Real-dependency build: JDK 17 --release 8; installed GTNH 2.9 RC2 Minecraft
  1.7.10 production SRG, Forge 10.13.4.1614, NEI 2.8.155-GTNH and OpenComputers
  1.12.64-GTNH. All 16 Java 8 classes and 1,367 member references pass API/SRG
  checks; metadata and common entrypoint loading pass -Xverify:all.
- Client regressions: 20 encoder, 38 reply parser, 74 field input, 77 editor
  (80 with installed lwjgl3ify 3.0.37), shared-buffer isolation, 12 pause controls,
  23 sync lifecycle and 34 gameplay/NEI hotkey checks.
- Thirteen Lua 5.2 suites: defaults, maintenance, timed refills, pause, idle
  polling, installer, settings, display, utility, clipboard receiver, manager,
  batch replies, and real extracted OpenOS buffered I/O.
- New scheduler tests run both the shipped template and missing-file fallbacks.
  They verify 60-second cycle/header timing, 300/3600-second stocked checks,
  300-second retries, five-second calculation polling, idle empty config,
  invalid-interval slow fallbacks and explicit/legacy fast-timing preservation.
- Actual installer refresh preserves all pre-profile timing values, including
  sleep=10, header=5, retry=60, cache=600, poll=1 and the old stock-delay table.
  Existing rollback, staged-download, recovery and fresh-install checks pass.
- Node config-editor suite: round trips, target/refill settings, backups,
  invalid imports and plain-number/paste-chunk output.
- Current Markdown links/anchors and Lua example syntax, known encoding markers,
  release archive CRCs, metadata, namespace, source contents and checksums checked.

Legacy fast-cadence tests now explicitly provide those settings so they continue
to validate supported overrides. No live TPS/MSPT improvement is claimed. The
optional Playwright browser and historical renderer-comparison suites were not
rerun. Full modpack gameplay, physical keyboard/tooltip rendering and real
network delivery remain separate acceptance checks.

See [build/tests](../../docs/DEVELOPMENT.md), [performance](../../docs/PERFORMANCE.md)
and [installation/adoption](../../docs/INSTALLATION.md). In particular, accepting
refreshed settings explanations does not replace saved old timing values.
