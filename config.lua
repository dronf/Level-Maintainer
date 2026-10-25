local cfg = {}

-- Fresh installs are idle: uncomment or add only the entries you need.
-- NEI additions are saved separately in nei_overrides.lua.
cfg.items = {
    -- ["Microprocessor"] = {low = 10, target = 64, batch = 16},
    -- ["Osmium Dust"] = {10000, 1000}, -- legacy fixed-batch threshold
    -- ["Blank Pattern"] = {nil, 64},   -- continuous; adds ongoing crafting work
}

-- Native fluids use mB (1,000 mB = one bucket), GTNH 2.9+.
cfg.fluids = {
    -- ["Ammonia"] = {low = 1000000, target = 1500000, batch = 100000},
}

-- Omit refillInterval for the normal low-load cycle. Set a positive interval
-- only when faster active refilling is needed; shorter intervals add CPU/job
-- queries. Example opt-in field: refillInterval = 30 (requires low and target).
-- Timings, retry and cache defaults are in settings.lua.
return cfg
