# SkillDock V1.0 设计文档

日期：2026-02-27  
状态：已确认，可进入实现

## 1. 目标与范围

本轮目标：交付 SkillDock 完整 V1（US-01/02/03/04/06/08/09/10/11/12/14），实现 skill 来源管理、项目隔离配置、搜索筛选、详情与同步。

不包含：skill 内容编辑、skill 导入导出、Trae/Trae CN 自动注入。

## 2. 总体方案

采用 MVVM：
- Views：渲染与交互
- ViewModels：状态与用例编排
- Services：扫描、解析、配置与文件系统能力
- Models：稳定可序列化的数据结构

交付策略采用纵向切片：
1. 来源目录管理 + 扫描展示
2. skill 启用/禁用与全局持久化
3. 项目管理与项目级配置
4. 详情页 + Finder 打开 + 收藏
5. 搜索筛选 + 一键同步 + 冲突处理

每个切片都满足：可运行、可手测、可回归。

## 3. 数据设计

### 3.1 核心模型

- Skill
  - `id`：稳定键（`sourcePath + folderName` 派生）
  - `name`、`description`
  - `sourceID`、`sourcePath`、`fullPath`
  - 运行时状态：是否启用

- Source
  - `id`、`path`、`displayName`、`addedAt`、`isBuiltIn`

- Project
  - `id`、`path`、`name`、`isFavorite`、`updatedAt`

- ProjectSkillConfig (`.skills-config.json`)
  - `version`
  - `appTargets`（Claude/Codex/Trae/Trae CN）
  - `skills`（`skillID -> enabled`）

- AppConfig（UserDefaults）
  - `sources`、`projects`、`selectedProjectID`、`selectedAppTarget`

### 3.2 兼容策略

- 读取 `.skills-config.json` 时忽略未知字段
- 版本不匹配时先兼容读取，按当前版本结构写回
- 配置损坏时回落默认配置并提示用户

## 4. 核心流程

### 4.1 启动

1. 加载 AppConfig
2. 并发扫描来源目录
3. 构建技能索引
4. 叠加当前项目与应用维度的启用状态
5. 输出视图模型状态

### 4.2 添加来源

1. 路径校验 + 去重 + 上限校验
2. 预扫描目录
3. 同名冲突检测
4. 用户选择冲突策略
5. 写配置并刷新列表

### 4.3 切换项目

1. 落盘当前项目配置
2. 读取目标项目 `.skills-config.json`
3. 无配置时创建默认配置
4. 刷新启用状态

### 4.4 一键同步

1. 重扫所有来源
2. 计算新增/删除/冲突 diff
3. 保持已有启用状态
4. 输出同步摘要（新增数、失败目录、冲突数）

## 5. 错误处理

- 目录不存在/无权限：跳过并记录错误
- `SKILL.md` 缺失或解析失败：跳过并计入告警
- 项目目录消失：提示并从列表移除
- 配置文件损坏：回落默认并写回

策略：局部失败不阻塞全局，始终返回“部分可用”结果。

## 6. 测试策略

- 单元测试
  - SkillMetadataParser：frontmatter 解析、空 description 回落
  - SkillScanner：目录扫描、符号链接、异常目录
  - ConfigManager：编解码、迁移、损坏恢复

- 集成测试
  - 添加来源、冲突处理、同步流程
  - 项目切换与项目级启用状态持久化

- 手动验收
  - 按 US-01/02/03/04/06/08/09/10/11/12/14 checklist 逐条过验收

## 7. 实施顺序

- Step 1：初始化工程（XcodeGen）+ 基础目录
- Step 2：完成切片 A（来源管理+扫描展示）
- Step 3：完成切片 B（全局启用状态）
- Step 4：完成切片 C（项目配置）
- Step 5：完成切片 D/E（详情、收藏、搜索、同步）
- Step 6：补齐测试和边界处理

## 8. 交付标准

- macOS 12+ 可运行
- 启动 < 2s（典型数据规模）
- 100 skills 扫描 < 5s（目标）
- 所有 V1 用户故事有可演示路径
