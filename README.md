# Konbini Brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/grozasaa-creator/roblox-brainrot-01-konbini/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/grozasaa-creator/roblox-brainrot-01-konbini/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A night-time konbini town where brainrot creatures drift down the street. Catch one, carry it home,
put it on a pedestal and let it earn. Built for the make.fun bounty roblox-brainrot-01.

Play: https://www.roblox.com/games/137333790241386

## Loop
1. Hold **E** on a drifting brainrot to catch it (the yellow arrow and the chevron trail show you where).
2. Carry it to your base (you move slower while carrying). Press **E** on a glowing empty pedestal.
3. Money builds up on the pedestal. Walk onto the pad or press **E** to collect.
4. Spend it: unlock the next rarity tier, buy boots, or rebirth for a permanent multiplier.

## Content
- 15 characters across 6 rarities (Common to Secret), 3 mutations (Gold x2, Neon x3, Glitch x5), 8 pedestals per base.
- Threats: the **NEON TIDE** wave (get inside a base or the konbini), other players stealing from unlocked
  pedestals, and patrol robots that stun you.
- Keys: **E** interact, **Q** drop, **C** codex. Everything also has an on-screen button.

## Layout
- `src/shared` config, rarity, mutations, economy, characters, shape helpers
- `src/server` world builder, state, spawning, carry, bases, stealing, tide, patrol, saving
- `src/client` HUD, guide (arrows, chevron trail, pillar), prompt gating, effects, codex
- `default.project.json` Rojo project; `game.rbxl` is built from it
- `main.ts` stages the submission dossier (Node 22): `MAKEFUN_OUTPUT_DIR=out node main.ts`

## Build
```
rojo build default.project.json --output game.rbxl
MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Visibility, guidance and text fit
- Lighting is bright (Brightness 3.5, Ambient and OutdoorAmbient raised, ExposureCompensation 0.9) with lamps,
  light ground and glowing pedestals so ground, pedestals and characters read clearly.
- Guidance without text: step chips, a chevron trail to the current goal, a bobbing arrow with highlight,
  a neon pillar on base/pad goals, and a safe-zone goal while the tide is out.
- Every label is TextScaled with padding and a size cap, inside frames with size constraints.

## License
MIT
