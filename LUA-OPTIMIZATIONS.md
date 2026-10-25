# Lua performance notes

The current guide is [docs/PERFORMANCE.md](docs/PERFORMANCE.md). It includes
idle-query suppression, targeted/cached lookups, stocked deadlines, timestamp
and display changes, tuning tradeoffs, and measured test counts.

Use [installation/update instructions](docs/INSTALLATION.md) for matching scripts.
Current scripts retain the rollback of additional CPU rescans. API-call
reductions do not establish a specific server MSPT improvement. Historical
measurements remain in the versioned client verification notes.
