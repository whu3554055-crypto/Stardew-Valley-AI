# `user://data_overrides` 加载约定（H1）

- **目录**：`user://data_overrides/`（运行时用户数据目录下自动创建）。
- **文件**：仅加载扩展名为 **`.json`** 的文件；按**文件名字典序**合并（后文件键覆盖先文件，见 `DataOverrides.get_merged_root()`）。
- **根类型**：每个文件根节点须为 **JSON 对象**；否则记录警告并跳过。
- **用途**：为未来「数据表覆盖 / Mod 轻量 JSON」预留；当前 **不** 自动改写 `ItemDatabase` / 作物表（接入点可后续按需添加）。

实现：`autoload/data_overrides.gd`（`DataOverrides`）。

---

## Mod 与正式存档签名（H2）

- **正式槽位存档**（`game_save_a.bundle` / `game_save_b.bundle`）使用 **HMAC** 校验核心字段；bundle 内可含扩展键（如 `world`），但 **签名载荷当前不纳入 `world`**，以免旧档失效（见 `scenes/main.gd` `_bundle_signing_payload`）。
- **`user://data_overrides/*.json`** 为**运行时覆盖**，不参与签名生成；若覆盖导致经济与物品异常，仍可能因**逻辑不一致**表现为「坏档体验」，但不会单独触发「签名不匹配」——除非未来将某类覆盖结果写入签名载荷并升 `SAVE_BUNDLE_VERSION`。
- **「创意档 / Mod 档」**若需完全关闭校验，需单独产品决策（例如第三槽位或 `user://` 平行 bundle）；当前代码**未**实现创意档开关。
