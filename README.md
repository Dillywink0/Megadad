# 8-Bit NES-Style Platformer (Godot 4)

## 🛠️ Project Architecture

This project uses a **code-first architecture**. Instead of relying on `.tscn` scene trees for level creation, stages are dynamically generated from ASCII character maps defined inside GDScript files.

* **`Main` (`scripts/main.gd`)**: Core manager controlling game initialization, camera shake, pause state, scene reloads, and screen transitions.
* **`GameManager` (`scripts/game_manager.gd`)**: Autoload singleton storing global state across level loads (lives, health, score, kills, checkpoint position).
* **`Level` (`scripts/Levels/level.gd`)**: Base class that parses ASCII text maps into solid tiles, collision boxes, hazards, pickups, platforms, and enemy instances.
* **`Player` (`scripts/player.gd`)**: Handles movement physics, jumping, sliding, hurt/invulnerability states, shooting, and death logic.
* **`Hud` (`scripts/hud.gd`)**: CanvasLayer overlay rendering health bars, score, kill counter, remaining lives, and stage transition announcements.

---

## 🗺️ Level ASCII Design Map Key

Levels are defined in `active_level_data["map"]` arrays using ASCII characters:

| Symbol | Element / Entity | Behavior / Notes |
| :--- | :--- | :--- |
| `#` | **Solid Block** | Collision tile matching stage theme (Brick, Metal, Factory, Crypt) |
| `P` | **Player Spawn** | Starting position for the stage |
| `G` | **Goal Pole** | Level exit trigger (`goal_reached` signal) |
| `^` | **Spike Hazard** | Instant kill area on contact |
| `C` | **Checkpoint** | Saves respawn location (`GameManager.checkpoint_pos`) |
| `M` | **Platform (Horizontal)** | Smoothly oscillating platform |
| `V` | **Platform (Vertical)** | Vertical oscillating platform for climbing shafts |
| `E` | **Enemy (Patrol)** | Basic walking enemy |
| `F` | **Enemy (Flyer)** | Sine-wave flying enemy |
| `H` | **Enemy (Turret)** | Stationary shooting hazard |
| `J` | **Enemy (Jumper)** | Periodically jumping enemy |
| `I` | **Item Pickup** | Health restore pickup |
| `B` | **Breakable Block** | Destroyable tile |
| `X` | **Boss Arena Marker** | Spawns Level 4 Boss encounter and locks entry |

---

## 🎮 Game Controls

| Action | Primary Input | Secondary / Controller |
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` or `Left` / `Right` | D-Pad / Left Stick |
| **Jump** | `Space` / `W` / `Up` | Face Button Bottom |
| **Shoot** | `J` or `Left Click` | Face Button Right |
| **Slide** | `S` / `Down` + `Jump` | Crouch + Jump |
| **Pause Game** | `Escape` | Start Button |
| **Toggle CRT Shader** | `F` | — |

---

## 📁 File & Directory Layout

```text
res://
├── assets/
│   └── fonts/          # PressStart2P.ttf (retro pixel font)
├── Sprites/
│   ├── enemies/        # Enemy and Boss spritesheets
│   ├── player/         # Player animation frames
│   ├── spritesheets/   # Level tilesets (Factory, Crypt, Sewer, Ocean)
│   └── tiles/          # Single brick, metal, and spike textures
├── Sound Effects/      # Gameplay SFX (.wav files)
└── scripts/
	├── main.gd         # Main game loop and pause handler
	├── game_manager.gd # Singleton for global game state
	├── hud.gd          # Retro UI overlay
	├── player.gd       # Player state machine & movement
	├── enemy.gd        # Enemy AI behaviors
	├── boss.gd         # Multi-phase final boss AI
	├── moving_platform.gd # Oscillating platform logic
	└── Levels/
		├── level.gd    # Base level parser
		├── level_2.gd  # Stage 2 (Metal Base)
		├── level_3.gd  # Stage 3 (Factory Gauntlet)
		└── level_4.gd  # Stage 4 (Crypt & Boss Room)
```

---

## 🚀 Quick Setup & Notes

1. **Godot Version:** Godot 4.x (Forward+ or Compatibility renderer).
2. **Font Integration:** Ensure `PressStart2P.ttf` is located in `res://assets/fonts/PressStart2P.ttf`.
3. **Sound Assets:** SFX paths map to `res://Sound Effects/` (`Jump.wav`, `Hit.wav`, `Shoot.wav`).
