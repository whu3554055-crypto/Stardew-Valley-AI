# `user://data_overrides` 加载约定（H1）

- **目录**：`user://data_overrides/`（运行时用户数据目录下自动创建）。
- **文件**：仅加载扩展名为 **`.json`** 的文件；按**文件名字典序**合并（后文件键覆盖先文件，见 `DataOverrides.get_merged_root()`）。
- **根类型**：每个文件根节点须为 **JSON 对象**；否则记录警告并跳过。
- **用途**：为未来「数据表覆盖 / Mod 轻量 JSON」预留；当前 **不** 自动改写 `ItemDatabase` / 作物表（接入点可后续按需添加）。

实现：`autoload/data_overrides.gd`（`DataOverrides`）。
