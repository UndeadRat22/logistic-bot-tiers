-- logistic-bot-tiers: configurable tier multipliers
-- Each setting controls one multiplier for one tier.
-- Defaults match the original hardcoded values.

local TIER_DEFAULTS = {
  fast     = { speed_mult = 1.5, cargo_add = 1, energy_mult = 1.5, energy_eff = 0.80, health_mult = 1.5 },
  express  = { speed_mult = 2.0, cargo_add = 2, energy_mult = 2.0, energy_eff = 0.65, health_mult = 2.0 },
  turbo    = { speed_mult = 2.5, cargo_add = 3, energy_mult = 2.5, energy_eff = 0.50, health_mult = 2.5 },
  advanced = { speed_mult = 2.5, cargo_add = 3, energy_mult = 2.5, energy_eff = 0.50, health_mult = 2.5 },
  superior = { speed_mult = 3.0, cargo_add = 4, energy_mult = 3.0, energy_eff = 0.35, health_mult = 3.0 },
}

local TIER_ORDER = { "fast", "express", "turbo", "advanced", "superior" }

local settings_list = {}

for _, tier_name in ipairs(TIER_ORDER) do
  local t = TIER_DEFAULTS[tier_name]
  local prefix = "lbt-" .. tier_name .. "-"

  settings_list[#settings_list + 1] = {
    type           = "double-setting",
    name           = prefix .. "speed-mult",
    setting_type   = "startup",
    default_value  = t.speed_mult,
    minimum_value  = 0.1,
    maximum_value  = 10.0,
    order          = prefix .. "1",
  }
  settings_list[#settings_list + 1] = {
    type           = "int-setting",
    name           = prefix .. "cargo-add",
    setting_type   = "startup",
    default_value  = t.cargo_add,
    minimum_value  = 0,
    maximum_value  = 100,
    order          = prefix .. "2",
  }
  settings_list[#settings_list + 1] = {
    type           = "double-setting",
    name           = prefix .. "energy-mult",
    setting_type   = "startup",
    default_value  = t.energy_mult,
    minimum_value  = 0.1,
    maximum_value  = 10.0,
    order          = prefix .. "3",
  }
  settings_list[#settings_list + 1] = {
    type           = "double-setting",
    name           = prefix .. "energy-eff",
    setting_type   = "startup",
    default_value  = t.energy_eff,
    minimum_value  = 0.01,
    maximum_value  = 5.0,
    order          = prefix .. "4",
  }
  settings_list[#settings_list + 1] = {
    type           = "double-setting",
    name           = prefix .. "health-mult",
    setting_type   = "startup",
    default_value  = t.health_mult,
    minimum_value  = 0.1,
    maximum_value  = 10.0,
    order          = prefix .. "5",
  }
end

data:extend(settings_list)
