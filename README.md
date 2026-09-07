# Bot Tiers

Tiered logistic and construction robots, parallel to transport belt tiers. Just as belts progress transport-belt → fast → express → turbo, this mod adds fast, express, turbo, advanced, and superior tiers for logistic and construction robots. Turbo requires Space Age; advanced requires Krastorio 2 without Space Age; superior requires Krastorio 2.

## How it works

Each tier is a new robot prototype with improved base stats:

| Tier | Speed | Cargo (logistic) | Energy Storage | Energy Eff. | Health | Tech |
| --- | --- | --- | --- | --- | --- | --- |
| Base | ×1 | 1 | ×1 | ×1.0 | ×1 | (vanilla) |
| Fast | ×1.5 | 2 | ×1.5 | ×0.80 | ×1.5 | Fast robotics |
| Express | ×2 | 3 | ×2 | ×0.65 | ×2 | Express robotics |
| Turbo | ×2.5 | 4 | ×2.5 | ×0.50 | ×2.5 | Turbo robotics |
| Advanced | ×2.5 | 4 | ×2.5 | ×0.50 | ×2.5 | Advanced robotics |
| Superior | ×3 | 5 | ×3 | ×0.35 | ×3 | Superior robotics |

Cargo shown is the resulting value for logistic robots (vanilla base 1 + tier bonus). Construction robots get the same additive bonus on top of their vanilla base (0).

Worker robot speed and cargo research bonuses apply on top of these base values, just like vanilla.

## Recipes

Each tier recipe consumes the previous tier, mirroring the belt upgrade chain:

| Tier | Extra Ingredients | Category |
| --- | --- | --- |
| Fast | iron-gear-wheel (5), steel-plate (1), electronic-circuit (3) | Crafting |
| Express | iron-gear-wheel (10), steel-plate (2), lubricant (20), advanced-circuit (2) | Crafting with fluid |
| Turbo | tungsten-plate (3), steel-plate (3), lubricant (20), processing-unit (1) | Crafting with fluid |
| Advanced | steel-plate (3), iron-gear-wheel (10), lubricant (20), processing-unit (1) | Crafting with fluid |
| Superior | imersite-gear-wheel (5)¹, steel-plate (3), lubricant (20), processing-unit (2) | Crafting with fluid |

Each recipe also consumes 1× of the previous tier robot (base robot for Fast, Fast for Express, etc.).

¹ Falls back to `imersite-crystal`, `kr-imersite-crystal`, or `kr-imersite-powder` if `imersite-gear-wheel` isn't available (Krastorio 2 prefix handling).

Both logistic and construction robots use the same per-tier circuit: electronic circuits for Fast, advanced circuits for Express, processing units for Turbo/Advanced/Superior.

## Technology

Dedicated technologies with chained prerequisites — each bot tech requires the previous bot tech plus the corresponding belt tech:

| Tech | Prerequisites | Unlocks |
| --- | --- | --- |
| Fast robotics | logistic-robotics + logistics-2 | fast-logistic-robot, fast-construction-robot |
| Express robotics | fast-robotics + logistics-3 | express-logistic-robot, express-construction-robot |
| Turbo robotics | express-robotics + turbo-transport-belt | turbo-logistic-robot, turbo-construction-robot |
| Advanced robotics | express-robotics + kr-logistic-4 | advanced-logistic-robot, advanced-construction-robot |
| Superior robotics | advanced-robotics² + kr-logistic-5 | superior-logistic-robot, superior-construction-robot |

Turbo robotics requires Space Age. Advanced robotics requires Krastorio 2 without Space Age. Superior robotics requires Krastorio 2. Without the corresponding mods, those tiers are simply absent.

² When Space Age is enabled, Superior robotics chains from Turbo robotics instead of Advanced (since Advanced is absent without Space Age).

## Notes

- Runs in `data-final-fixes.lua` so base game's `data-updates.lua` doesn't overwrite scaled values.
- Quality (from the Space Age expansion) applies to tiered bots the same way it applies to vanilla bots.
- No runtime scripting — all improvements are prototype-level, so there's no performance impact.

## Testing

```
make test-e2e                  # vanilla + Space Age
sh tests/run-e2e-k2.sh         # Krastorio 2 + Space Age
sh tests/run-e2e-k2-nosa.sh    # Krastorio 2 without Space Age (advanced tier)
```

All three run against a real headless Factorio instance, verifying all prototypes, recipes, tech unlocks, and stat scaling at runtime.
