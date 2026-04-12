# 地块美术约定（A3）

## 规格

- **主网格**：`32×32` px（与 `terrain_atlas_32.png`、`GameTileMap` 中 `TileSet.tile_size` 一致）。
- **采样**：像素风资源使用 **Nearest**；在 `Sprite2D` / `TextureRect` 上显式 `texture_filter = TEXTURE_FILTER_NEAREST`（与项目玩家一致）。

## 现有资源

| 文件 | 说明 |
|------|------|
| `terrain_atlas_32.png` | 单行 11 格：草/土/田/水/石/木地板/沙/石砖/花/树/栅栏（与 `game_tilemap.gd` 枚举顺序一致） |

## 命名建议（后续扩展）

- `world_<区域>_<主题>_32.png` — 区域专用 atlas。
- 导入后 `.import` 由 Godot 管理；策划表只引用 `res://` 路径。

## 与多场景关系

- 每个 `world_*.tscn` 可使用同一 `TileSet` 源或独立 atlas；请在 `scenes/world/README.md` 备注该场景主 tile 来源。
- **`playground_tileset.tres`**：`world_playground`、**`world_town`**、**`world_mine`**、**`world_beach`**、**`world_forest`**（F1）共用；`WorldTileBackdrop`（`scripts/world/world_tile_backdrop.gd`）封装各壳铺图。
