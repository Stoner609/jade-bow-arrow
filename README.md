# Rogue-game

A small portrait mobile Archero-like action roguelite prototype built in Godot 4.5.

## Play

- Move with the on-screen joystick, `WASD`, or arrow keys.
- Stop moving to automatically fire at the nearest enemy.
- Dodge melee enemies and purple projectiles.
- Pick up blue XP orbs and green hearts.
- Tap an upgrade card, or choose with `1`, `2`, or `3` when you level up.
- Clear each room's waves and enter the glowing gate.
- Survive through room 8 and defeat the boss to win.
- Press `R` to restart after death or victory.

## Test

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
```

## Code Structure

- `scripts/core/`: game controller, shared constants, and run-level state.
- `scripts/actors/`: player and enemy data/behavior helpers.
- `scripts/projectiles/`: player arrows and enemy shots.
- `scripts/pickups/`: XP and healing pickup helpers.
- `scripts/rooms/`: room layout, gate, and spawn positioning helpers.
- `scripts/ui/`: HUD, upgrade choices, and touch-control helpers.
- `scripts/utils/`: shared collision helpers.
