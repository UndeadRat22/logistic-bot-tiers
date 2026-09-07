-- logistic-bot-tiers: tiered logistic and construction robots, parallel to transport
-- belt tiers.  Fast → Express → (Turbo or Advanced) → (Superior if Krastorio 2).
--
-- Turbo requires Space Age; Advanced requires K2 without Space Age.
-- Runs in data-final-fixes so base game data-updates (which modify robot
-- prototypes) have already applied — we scale the *final* vanilla values.

------------------------------------------------------------------------------
-- Tier configuration
------------------------------------------------------------------------------

local TIERS = {
  fast = {
    speed_mult  = 1.5,
    cargo_add   = 1,
    energy_mult = 1.5,
    energy_eff  = 0.80,
    health_mult = 1.5,
    tint        = { r = 0.75, g = 0.55, b = 0.55, a = 1.0 },
    -- Tech prerequisites: previous bot tech + corresponding belt tech
    belt_tech   = "logistics-2",
    ingredients = {
      { type = "item", name = "iron-gear-wheel", amount = 5 },
      { type = "item", name = "steel-plate",     amount = 1 },
    },
    energy_required = 2,
    circuit = { type = "item", name = "electronic-circuit", amount = 3 },
  },
  express = {
    speed_mult  = 2.0,
    cargo_add   = 2,
    energy_mult = 2.0,
    energy_eff  = 0.65,
    health_mult = 2.0,
    tint        = { r = 0.55, g = 0.65, b = 0.80, a = 1.0 },
    belt_tech   = "logistics-3",
    ingredients = {
      { type = "item",  name = "iron-gear-wheel", amount = 10 },
      { type = "item",  name = "steel-plate",     amount = 2 },
      { type = "fluid", name = "lubricant",       amount = 20 },
    },
    energy_required = 4,
    categories       = { "crafting-with-fluid" },
    circuit = { type = "item", name = "advanced-circuit", amount = 2 },
  },
  turbo = {
    speed_mult  = 2.5,
    cargo_add   = 3,
    energy_mult = 2.5,
    energy_eff  = 0.50,
    health_mult = 2.5,
    tint        = { r = 0.55, g = 0.75, b = 0.55, a = 1.0 },
    belt_tech   = "turbo-transport-belt",
    ingredients = {
      { type = "item",  name = "tungsten-plate",  amount = 3 },
      { type = "item",  name = "steel-plate",     amount = 3 },
      { type = "fluid", name = "lubricant",       amount = 20 },
    },
    energy_required = 6,
    categories         = { "crafting-with-fluid" },
    requires_space_age = true,
    circuit = { type = "item", name = "processing-unit", amount = 1 },
  },
  advanced = {
    speed_mult  = 2.5,
    cargo_add   = 3,
    energy_mult = 2.5,
    energy_eff  = 0.50,
    health_mult = 2.5,
    tint        = { r = 0.50, g = 0.75, b = 0.50, a = 1.0 },
    belt_tech   = "kr-logistic-4",
    ingredients = {
      { type = "item",  name = "steel-plate",     amount = 3 },
      { type = "item",  name = "iron-gear-wheel", amount = 10 },
      { type = "fluid", name = "lubricant",       amount = 20 },
    },
    energy_required = 6,
    categories               = { "crafting-with-fluid" },
    requires_krastorio_no_sa = true,
    circuit = { type = "item", name = "processing-unit", amount = 1 },
  },
  superior = {
    speed_mult  = 3.0,
    cargo_add   = 4,
    energy_mult = 3.0,
    energy_eff  = 0.35,
    health_mult = 3.0,
    tint        = { r = 0.70, g = 0.55, b = 0.75, a = 1.0 },
    belt_tech   = "kr-logistic-5",
    ingredients = {
      { type = "item",  name = "imersite-gear-wheel", amount = 5 },
      { type = "item",  name = "steel-plate",         amount = 3 },
      { type = "fluid", name = "lubricant",            amount = 20 },
    },
    energy_required = 8,
    categories         = { "crafting-with-fluid" },
    requires_krastorio = true,
    circuit = { type = "item", name = "processing-unit", amount = 2 },
  },
}

local TIER_ORDER = { "fast", "express", "turbo", "advanced", "superior" }

-- Tech names for our dedicated bot-tier technologies
local TECH_NAMES = {
  fast      = "logistic-bot-tiers-fast-robotics",
  express   = "logistic-bot-tiers-express-robotics",
  turbo     = "logistic-bot-tiers-turbo-robotics",
  advanced  = "logistic-bot-tiers-advanced-robotics",
  superior  = "logistic-bot-tiers-superior-robotics",
}

local BOT_TYPES = {
  {
    entity_type = "logistic-robot",
    base_name   = "logistic-robot",
  },
  {
    entity_type = "construction-robot",
    base_name   = "construction-robot",
  },
}

------------------------------------------------------------------------------
-- Apply user-configurable settings (settings.lua)
------------------------------------------------------------------------------

local function get_setting(name, default)
  local s = settings.startup[name]
  if s and s.value ~= nil then return s.value end
  return default
end

for _, tier_name in ipairs(TIER_ORDER) do
  local tier = TIERS[tier_name]
  local prefix = "lbt-" .. tier_name .. "-"
  tier.speed_mult  = get_setting(prefix .. "speed-mult",  tier.speed_mult)
  tier.cargo_add   = get_setting(prefix .. "cargo-add",   tier.cargo_add)
  tier.energy_mult = get_setting(prefix .. "energy-mult", tier.energy_mult)
  tier.energy_eff  = get_setting(prefix .. "energy-eff",  tier.energy_eff)
  tier.health_mult = get_setting(prefix .. "health-mult", tier.health_mult)
end

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

local function scale_energy(value, mult)
  if type(value) == "number" then return value * mult end
  if type(value) ~= "string" then return value end
  local n, u = value:match("^([%d%.]+)%s*([A-Za-z]*)$")
  if not n then return value end
  return tostring(tonumber(n) * mult) .. (u or "")
end

local function get_icon(proto)
  if proto.icons and proto.icons[1] then
    local layer = proto.icons[1]
    return layer.icon, layer.icon_size or proto.icon_size
  end
  return proto.icon, proto.icon_size
end

local function tinted_icons(icon, icon_size, tint)
  if not icon then return nil end
  return { { icon = icon, icon_size = icon_size, tint = tint } }
end

------------------------------------------------------------------------------
-- Determine which tiers are available
------------------------------------------------------------------------------

local has_space_age = data.raw.technology["turbo-transport-belt"] ~= nil

local has_krastorio = mods["Krastorio2"] ~= nil or mods["Krastorio2-spaced-out"] ~= nil
if has_krastorio then
  has_krastorio = data.raw.technology["kr-logistic-5"] ~= nil
end

-- Fix imersite ingredient name — K2 prefixes items with kr-
local imersite_gear = "imersite-gear-wheel"
if has_krastorio and not data.raw.item[imersite_gear] then
  for _, candidate in ipairs({ "imersite-crystal", "kr-imersite-crystal", "kr-imersite-powder" }) do
    if data.raw.item[candidate] then
      imersite_gear = candidate
      break
    end
  end
  if not data.raw.item[imersite_gear] then
    has_krastorio = false
  end
end

-- Determine the "base" bot tech that the first tier depends on.
-- Vanilla: logistic-robotics (logistic) / construction-robotics (construction)
-- We use logistic-robotics as the common prerequisite since it unlocks roboports.
local base_bot_tech = "logistic-robotics"
if not data.raw.technology[base_bot_tech] then
  base_bot_tech = "construction-robotics"
end

------------------------------------------------------------------------------
-- Create tiered entities, items, and recipes
------------------------------------------------------------------------------

local new_entities = {}
local new_items    = {}
local new_recipes  = {}
local new_techs    = {}

for _, bot in ipairs(BOT_TYPES) do
  local base_entity = data.raw[bot.entity_type][bot.base_name]
  local base_item   = data.raw.item[bot.base_name]
  if not base_entity or not base_item then
    error("logistic-bot-tiers: vanilla prototype '" .. bot.base_name .. "' not found")
  end

  local prev_name = bot.base_name

  for tier_idx, tier_name in ipairs(TIER_ORDER) do
    local tier = TIERS[tier_name]

    -- Skip tiers whose requirements aren't met
    local skip = false
    if tier.requires_space_age and not has_space_age then skip = true end
    if tier.requires_krastorio and not has_krastorio then skip = true end
    if tier.requires_krastorio_no_sa then
      if not has_krastorio or has_space_age then skip = true end
    end

    if not skip then
      local tier_copy = table.deepcopy(tier)
      if tier_name == "superior" then
        for _, ing in ipairs(tier_copy.ingredients) do
          if ing.name == "imersite-gear-wheel" then
            ing.name = imersite_gear
          end
        end
      end

      local new_name = tier_name .. "-" .. bot.base_name

      --------------------------------------------------------------------
      -- Entity
      --------------------------------------------------------------------
      local ent = table.deepcopy(base_entity)
      ent.name = new_name

      local e_icon, e_icon_size = get_icon(base_entity)
      ent.icons = tinted_icons(e_icon, e_icon_size, tier.tint)
      ent.icon  = nil

      ent.speed = base_entity.speed * tier_copy.speed_mult
      if base_entity.max_speed then
        ent.max_speed = base_entity.max_speed * tier_copy.speed_mult
      end

      if ent.max_payload_size then
        ent.max_payload_size = base_entity.max_payload_size + tier_copy.cargo_add
      end
      if ent.max_payload_size_after_bonus then
        ent.max_payload_size_after_bonus = base_entity.max_payload_size_after_bonus + tier_copy.cargo_add
      end

      if base_entity.max_energy then
        ent.max_energy = scale_energy(base_entity.max_energy, tier_copy.energy_mult)
      end
      if base_entity.energy_per_move then
        ent.energy_per_move = scale_energy(base_entity.energy_per_move, tier_copy.energy_eff)
      end
      if base_entity.energy_per_tick then
        ent.energy_per_tick = scale_energy(base_entity.energy_per_tick, tier_copy.energy_eff)
      end

      if ent.max_health then
        ent.max_health = math.floor(base_entity.max_health * tier_copy.health_mult + 0.5)
      end

      ent.minable = { mining_time = 0.1, result = new_name }
      ent.localised_name = { "entity-name." .. new_name }

      new_entities[#new_entities + 1] = ent

      --------------------------------------------------------------------
      -- Item
      --------------------------------------------------------------------
      local item = table.deepcopy(base_item)
      item.name = new_name

      local i_icon, i_icon_size = get_icon(base_item)
      item.icons = tinted_icons(i_icon, i_icon_size, tier.tint)
      item.icon  = nil

      item.place_result = new_name
      item.order = "a[robot]-" .. string.char(97 + tier_idx * 2) .. "[" .. tier_name .. "-" .. bot.base_name .. "]"
      item.localised_name = { "item-name." .. new_name }

      new_items[#new_items + 1] = item

      --------------------------------------------------------------------
      -- Recipe (chained: consumes previous tier)
      --------------------------------------------------------------------
      local recipe = {
        type            = "recipe",
        name            = new_name,
        enabled         = false,
        energy_required = tier_copy.energy_required,
        ingredients     = {
          { type = "item", name = prev_name, amount = 1 },
        },
        results = {
          { type = "item", name = new_name, amount = 1 },
        },
      }

      for _, ing in ipairs(tier_copy.ingredients) do
        recipe.ingredients[#recipe.ingredients + 1] = table.deepcopy(ing)
      end
      recipe.ingredients[#recipe.ingredients + 1] = table.deepcopy(tier_copy.circuit)

      if tier_copy.categories then
        recipe.categories = tier_copy.categories
      end

      new_recipes[#new_recipes + 1] = recipe

      prev_name = new_name
    end
  end
end

data:extend(new_entities)
data:extend(new_items)
data:extend(new_recipes)

------------------------------------------------------------------------------
-- Dedicated technologies with chained prerequisites
--
-- fast-robotics      ← base_bot_tech + logistics-2 (fast belts)
-- express-robotics    ← fast-robotics + logistics-3 (express belts)
-- turbo-robotics      ← express-robotics + turbo-transport-belt
-- superior-robotics  ← turbo-robotics + kr-logistic-5 (K2 superior belts)
------------------------------------------------------------------------------

local prev_tech = base_bot_tech

for tier_idx, tier_name in ipairs(TIER_ORDER) do
  local tier = TIERS[tier_name]
  local skip = false
  if tier.requires_space_age and not has_space_age then skip = true end
  if tier.requires_krastorio and not has_krastorio then skip = true end
  if tier.requires_krastorio_no_sa then
    if not has_krastorio or has_space_age then skip = true end
  end

  if not skip then
    local tech_name = TECH_NAMES[tier_name]
    local belt_tech = data.raw.technology[tier.belt_tech]
    if not belt_tech then
      -- Belt tech doesn't exist; fall back to just prev_tech
      -- (shouldn't normally happen since we check availability above)
      skip = true
    else
      -- Build prerequisites: previous bot tech + corresponding belt tech
      local prereqs = { prev_tech }
      if prev_tech ~= tier.belt_tech then
        table.insert(prereqs, tier.belt_tech)
      end

      -- Copy science cost from the corresponding belt tech
      local unit = table.deepcopy(belt_tech.unit) or {
        count = 100 * tier_idx,
        time = 30,
        ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } },
      }

      -- Use the vanilla robotics technology icon for all bot-tier techs
      local robotics_tech = data.raw.technology[base_bot_tech]

      local tech = {
        type            = "technology",
        name            = tech_name,
        localised_name  = { "technology-name." .. tech_name },
        icon            = robotics_tech and robotics_tech.icon or nil,
        icons           = robotics_tech and robotics_tech.icons or nil,
        icon_size       = (robotics_tech and robotics_tech.icon_size) or 256,
        order           = "c-a-" .. string.char(97 + tier_idx),
        prerequisites   = prereqs,
        unit            = unit,
        effects         = {},
      }

      -- Add recipe unlocks
      for _, bot in ipairs(BOT_TYPES) do
        local recipe_name = tier_name .. "-" .. bot.base_name
        if data.raw.recipe[recipe_name] then
          table.insert(tech.effects, {
            type   = "unlock-recipe",
            recipe = recipe_name,
          })
        end
      end

      new_techs[#new_techs + 1] = tech
      prev_tech = tech_name
    end
  end
end

data:extend(new_techs)
