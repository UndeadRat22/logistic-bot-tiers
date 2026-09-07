-- E2E harness for logistic-bot-tiers (run via tests/run-e2e.sh).
--
-- Verifies at runtime against a real headless Factorio server:
--   1. Tiered entity prototypes exist with correctly scaled stats
--   2. Tiered items exist and place_result matches the entity
--   3. Recipes exist, are disabled by default, and chain correctly
--   4. Recipe ingredients match the belt-tier parallel
--   5. Dedicated technologies exist with correct prerequisites and recipe unlocks
--   6. Express/turbo/superior recipes have the crafting-with-fluid category

local function check(cond, label)
  log("E2E " .. (cond and "PASS" or "FAIL") .. " " .. label)
end

local TIER_CONFIG = {
  fast     = { speed_mult = 1.5, cargo_add = 1, energy_mult = 1.5, energy_eff = 0.80, health_mult = 1.5, belt_tech = "logistics-2" },
  express  = { speed_mult = 2.0, cargo_add = 2, energy_mult = 2.0, energy_eff = 0.65, health_mult = 2.0, belt_tech = "logistics-3" },
  turbo    = { speed_mult = 2.5, cargo_add = 3, energy_mult = 2.5, energy_eff = 0.50, health_mult = 2.5, belt_tech = "turbo-transport-belt" },
  advanced = { speed_mult = 2.5, cargo_add = 3, energy_mult = 2.5, energy_eff = 0.50, health_mult = 2.5, belt_tech = "kr-logistic-4" },
  superior = { speed_mult = 3.0, cargo_add = 4, energy_mult = 3.0, energy_eff = 0.35, health_mult = 3.0, belt_tech = "kr-logistic-5" },
}

local TECH_NAMES = {
  fast     = "logistic-bot-tiers-fast-robotics",
  express  = "logistic-bot-tiers-express-robotics",
  turbo    = "logistic-bot-tiers-turbo-robotics",
  advanced = "logistic-bot-tiers-advanced-robotics",
  superior = "logistic-bot-tiers-superior-robotics",
}

local BOT_TYPES = { "logistic-robot", "construction-robot" }
local TIER_ORDER = { "fast", "express", "turbo", "advanced", "superior" }

local TIER_EXTRA_INGREDIENTS = {
  fast     = { { type = "item", name = "iron-gear-wheel", amount = 5 }, { type = "item", name = "steel-plate", amount = 1 } },
  express  = { { type = "item", name = "iron-gear-wheel", amount = 10 }, { type = "item", name = "steel-plate", amount = 2 }, { type = "fluid", name = "lubricant", amount = 20 } },
  turbo    = { { type = "item", name = "tungsten-plate", amount = 3 }, { type = "item", name = "steel-plate", amount = 3 }, { type = "fluid", name = "lubricant", amount = 20 } },
  advanced = { { type = "item", name = "steel-plate", amount = 3 }, { type = "item", name = "iron-gear-wheel", amount = 10 }, { type = "fluid", name = "lubricant", amount = 20 } },
  superior = { { type = "item", name = "imersite-gear-wheel", amount = 5 }, { type = "item", name = "steel-plate", amount = 3 }, { type = "fluid", name = "lubricant", amount = 20 } },
}

-- Per-tier circuit: green for fast, red for express, processing-unit for turbo/superior
local CIRCUIT_FOR_TIER = {
  fast     = { type = "item", name = "electronic-circuit", amount = 3 },
  express  = { type = "item", name = "advanced-circuit",  amount = 2 },
  turbo    = { type = "item", name = "processing-unit",   amount = 1 },
  advanced = { type = "item", name = "processing-unit",   amount = 1 },
  superior = { type = "item", name = "processing-unit",   amount = 2 },
}

local function tier_available(tier_name, has_space_age, has_krastorio)
  if tier_name == "turbo" then return has_space_age end
  if tier_name == "advanced" then return has_krastorio and not has_space_age end
  if tier_name == "superior" then return has_krastorio end
  return true
end

script.on_event(defines.events.on_tick, function()
  if game.tick < 10 then return end
  if storage.done then return end
  storage.done = true

  local has_space_age = prototypes.entity["turbo-transport-belt"] ~= nil
  local has_krastorio = prototypes.technology["kr-logistic-5"] ~= nil
  local imersite_name = "imersite-gear-wheel"
  if has_krastorio and not prototypes.item[imersite_name] then
    for _, candidate in ipairs({ "imersite-crystal", "kr-imersite-crystal", "kr-imersite-powder" }) do
      if prototypes.item[candidate] then
        imersite_name = candidate
        break
      end
    end
  end

  -- Determine the base bot tech
  local base_bot_tech = "logistic-robotics"
  if not prototypes.technology[base_bot_tech] then
    base_bot_tech = "construction-robotics"
  end

  local base_speed = {}
  local base_cargo = {}
  for _, bot in ipairs(BOT_TYPES) do
    base_speed[bot] = prototypes.entity[bot].speed
    base_cargo[bot]  = prototypes.entity[bot].max_payload_size
  end

  local function measure_entity_stat(name, field)
    local surface = game.surfaces[1]
    local pos = surface.find_non_colliding_position("logistic-robot", { math.random(-50, 50), math.random(-50, 50) }, 100, 4)
    if not pos then return nil end
    local ent = surface.create_entity({ name = name, position = pos, force = "player" })
    if not ent or not ent.valid then return nil end
    local val
    if field == "energy" then
      ent.energy = 1e12
      val = ent.energy
    elseif field == "health" then
      val = ent.health
    end
    ent.destroy()
    return val
  end

  local base_energy = {}
  local base_health = {}
  for _, bot in ipairs(BOT_TYPES) do
    base_energy[bot] = measure_entity_stat(bot, "energy")
    base_health[bot] = measure_entity_stat(bot, "health")
  end

  ------------------------------------------------------------
  -- 1. Entity prototypes exist with scaled stats
  ------------------------------------------------------------
  for _, bot in ipairs(BOT_TYPES) do
    for _, tier_name in ipairs(TIER_ORDER) do
      local avail = tier_available(tier_name, has_space_age, has_krastorio)
      if not avail then
        local proto = prototypes.entity[tier_name .. "-" .. bot]
        check(proto == nil, tier_name .. "-" .. bot .. " entity absent (mod not installed)")
      else
        local name = tier_name .. "-" .. bot
        local proto = prototypes.entity[name]
        check(proto ~= nil, name .. " entity prototype exists")
        if proto then
          local tc = TIER_CONFIG[tier_name]
          check(math.abs(proto.speed - base_speed[bot] * tc.speed_mult) < 1e-9,
            name .. " speed = base*" .. tc.speed_mult .. " (got " .. tostring(proto.speed) .. ")")
          local expected_cargo = base_cargo[bot] + tc.cargo_add
          check(proto.max_payload_size == expected_cargo,
            name .. " max_payload_size = " .. expected_cargo .. " (got " .. tostring(proto.max_payload_size) .. ")")
          if base_health[bot] then
            local tier_health = measure_entity_stat(name, "health")
            local expected_health = math.floor(base_health[bot] * tc.health_mult + 0.5)
            check(tier_health ~= nil and tier_health == expected_health,
              name .. " max_health = " .. expected_health .. " (got " .. tostring(tier_health) .. ")")
          end
          local base_epm = prototypes.entity[bot].energy_per_move
          if base_epm then
            local expected_epm = base_epm * tc.energy_eff
            check(proto.energy_per_move ~= nil and math.abs(proto.energy_per_move - expected_epm) < 1e-6,
              name .. " energy_per_move = base*" .. tc.energy_eff .. " (got " .. tostring(proto.energy_per_move) .. ")")
          end
          local base_ept = prototypes.entity[bot].energy_per_tick
          if base_ept then
            local expected_ept = base_ept * tc.energy_eff
            check(proto.energy_per_tick ~= nil and math.abs(proto.energy_per_tick - expected_ept) < 1e-6,
              name .. " energy_per_tick = base*" .. tc.energy_eff .. " (got " .. tostring(proto.energy_per_tick) .. ")")
          end
          local tier_energy = measure_entity_stat(name, "energy")
          if base_energy[bot] and tier_energy then
            local expected_energy = base_energy[bot] * tc.energy_mult
            check(math.abs(tier_energy - expected_energy) < 1.0,
              name .. " max_energy = base*" .. tc.energy_mult .. " (got " .. tostring(tier_energy) .. ")")
          else
            check(false, name .. " max_energy could not be measured")
          end
        end
      end
    end
  end

  ------------------------------------------------------------
  -- 2. Items exist with correct place_result
  ------------------------------------------------------------
  for _, bot in ipairs(BOT_TYPES) do
    for _, tier_name in ipairs(TIER_ORDER) do
      if tier_available(tier_name, has_space_age, has_krastorio) then
        local name = tier_name .. "-" .. bot
        local item = prototypes.item[name]
        check(item ~= nil, name .. " item exists")
        if item then
          check(item.place_result ~= nil and item.place_result.name == name,
            name .. " item place_result matches (got " .. tostring(item.place_result and item.place_result.name) .. ")")
        end
      end
    end
  end

  ------------------------------------------------------------
  -- 3. Recipes exist, disabled, chained, correct ingredients
  ------------------------------------------------------------
  for _, bot in ipairs(BOT_TYPES) do
    local prev_name = bot
    for _, tier_name in ipairs(TIER_ORDER) do
      if tier_available(tier_name, has_space_age, has_krastorio) then
        local name = tier_name .. "-" .. bot
        local recipe = prototypes.recipe[name]
        check(recipe ~= nil, name .. " recipe exists")
        if recipe then
          check(recipe.enabled == false, name .. " recipe disabled by default")
          local has_prev = false
          for _, ing in pairs(recipe.ingredients) do
            if ing.name == prev_name and ing.amount == 1 then has_prev = true end
          end
          check(has_prev, name .. " recipe consumes 1x " .. prev_name)
          local circuit = CIRCUIT_FOR_TIER[tier_name]
          local has_circuit = false
          for _, ing in pairs(recipe.ingredients) do
            if ing.name == circuit.name and ing.amount == circuit.amount then has_circuit = true end
          end
          check(has_circuit, name .. " recipe has " .. circuit.amount .. "x " .. circuit.name)
          local extras = TIER_EXTRA_INGREDIENTS[tier_name]
          for _, expected_ing in ipairs(extras) do
            local ing_name = expected_ing.name
            if ing_name == "imersite-gear-wheel" and has_krastorio then
              ing_name = imersite_name
            end
            local found = false
            for _, ing in pairs(recipe.ingredients) do
              if ing.name == ing_name and ing.amount == expected_ing.amount then found = true end
            end
            check(found, name .. " recipe has " .. expected_ing.amount .. "x " .. ing_name)
          end
          if tier_name == "express" or tier_name == "turbo" or tier_name == "advanced" or tier_name == "superior" then
            local has_fluid_cat = false
            if recipe.categories then
              for _, cat in pairs(recipe.categories) do
                if cat == "crafting-with-fluid" then has_fluid_cat = true end
              end
            end
            check(has_fluid_cat, name .. " recipe has crafting-with-fluid category")
          end
        end
        prev_name = name
      end
    end
  end

  ------------------------------------------------------------
  -- 4. Dedicated technologies with correct prerequisites & unlocks
  ------------------------------------------------------------
  local prev_tech = base_bot_tech
  for _, tier_name in ipairs(TIER_ORDER) do
    if tier_available(tier_name, has_space_age, has_krastorio) then
      local tech_name = TECH_NAMES[tier_name]
      local tc = TIER_CONFIG[tier_name]
      local tech = prototypes.technology[tech_name]
      check(tech ~= nil, tech_name .. " technology exists")
      if tech then
        -- Check prerequisites contain previous bot tech
        local has_prev_prereq = false
        if tech.prerequisites then
          for _, prereq in pairs(tech.prerequisites) do
            local pname = type(prereq) == "string" and prereq or prereq.name
            if pname == prev_tech then has_prev_prereq = true end
          end
        end
        check(has_prev_prereq, tech_name .. " requires " .. prev_tech)

        -- Check prerequisites contain the corresponding belt tech
        local has_belt_prereq = false
        if tech.prerequisites then
          for _, prereq in pairs(tech.prerequisites) do
            local pname = type(prereq) == "string" and prereq or prereq.name
            if pname == tc.belt_tech then has_belt_prereq = true end
          end
        end
        check(has_belt_prereq, tech_name .. " requires " .. tc.belt_tech)

        -- Check recipe unlocks
        for _, bot in ipairs(BOT_TYPES) do
          local recipe_name = tier_name .. "-" .. bot
          local found = false
          if tech.effects then
            for _, effect in pairs(tech.effects) do
              if effect.type == "unlock-recipe" and effect.recipe == recipe_name then found = true end
            end
          end
          check(found, tech_name .. " unlocks " .. recipe_name)
        end
      end
      prev_tech = tech_name
    end
  end

  log("E2E DONE")
end)
