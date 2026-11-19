# Konbini Brainrot

A 3D Roblox game for make.fun's roblox-brainrot-01 bounty. A neon-lit night town of convenience stores is overrun by
original "brainrot" critters. Catch them, run them home, and let them earn while you are away.

## The loop

1. Hold E on a wild critter to catch it. Carrying it slows you down.
2. Run it into your own base: it is placed on a pedestal and starts earning money per second.
3. Collect the pedestal's meter, then spend it: buy critters off the conveyor belt, unlock the next rarity tier,
   buy dash boots, or rebirth for a permanent income multiplier.

15 original characters in 6 rarity tiers (Common, Rare, Epic, Legendary, Mythic, Secret), with three mutations
(Gold, Neon, Glitch) that multiply income. A Codex (press C) tracks what you have found.

## Threats

- **Neon Tide**: a warning, then a wave sweeps the street. Be inside a base or a konbini or you drop what you carry.
- **Stealing**: hold F near a carried critter or a pedestal to take it. Lock your base to protect your pedestals.
- **Security robots** patrol the street and make carriers drop their catch.

## Layout

- `src/shared`: constants, rarity, mutations, characters, character models, economy, remotes.
- `src/server`: one service per responsibility (world, base, spawn, carry, steal, patrol, tide, actions, state, saving).
- `src/client`: display and input only (HUD, labels, carry keys, effects, codex). The server decides everything.
- `default.project.json`: Rojo project. `rojo build default.project.json --output game.rbxl` builds `game.rbxl`.
- `main.ts`: hands the entry in (copies `game.rbxl`, `src/`, `screenshots/`, `PLAY.json` and writes `dossier.json`).

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
