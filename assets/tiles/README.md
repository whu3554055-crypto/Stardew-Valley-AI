# Terrain atlas

- `terrain_atlas_32.png` — single row of **11×32×32** tiles matching `TileType` in `scripts/game_tilemap.gd` (grass, dirt, tilled, water, stone, wood floor, sand, cobblestone, flower bed, tree, fence).
- Regenerate with `python` (see repo root tooling) or replace with hand-painted strip; `GameTileMap` loads this path in `_create_main_tileset()`.
