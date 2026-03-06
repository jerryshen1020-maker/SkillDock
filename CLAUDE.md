# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
本文件定位为“项目快照入口”，不是详细流水日志；详细变更统一记录在 `docs/logs/PROJECT_LOG.md`。

## 项目概述

- **名称**: SkillDock
- **类型**: macOS 原生应用 (SwiftUI)
- **目的**: 统一管理 AI 工具的 skill，支持多应用统一同步与全局开关
- **兼容性**: macOS 12.0+

## 当前状态

### v1.0
Task 1-9 已完成（工程初始化 + 核心模型 + 元数据解析与扫描 + 来源目录管理闭环 + 全局启用/禁用 + 详情与搜索筛选 + 一键同步与冲突处理 + 文档收口与发布检查）。

### v1.1
已完成第一轮实现与对齐：
- UI 主骨架：顶部标题栏 + 入口式侧边栏 + 分层内容区
- 目录选择器：`NSOpenPanel` 系统弹窗
- 递归扫描：自动遍历子文件夹
- 默认全局目录：启动时导入 `~/.claude/skills/`
- Skill 开关生效：同步项目级 `.claude/settings.json` permissions
当前进入第二轮细节打磨（状态样式与像素级对齐）。

### v1.2
已完成全量需求与 UI 对齐：
- 核心功能：移除项目逻辑，改为纯全局应用管理（Claude Code, Codex, OpenCode, Trae, Trae CN）。
- 来源管理：本地目录 + Git 仓库（支持克隆、批量更新、失败重试）。
- UI 对齐：移除侧边栏“Skill 仓库”，调整“来源管理”位置，重构来源管理布局，对齐 v1.2 设计稿。
- 交互优化：新增应用切换转场动画，支持 Hover 预览切换。
- 回归体系：新增视觉回归测试（VisualSnapshotCaptureUITests）与 CI 门禁（GitHub Actions）。
- 兼容性：修复 `/var` 路径兼容与 `Skills:` 权限前缀写入。

- PRD: `docs/prd/PRD-003.md`
- v1.2 设计规范: `docs/specs/v1.2-ui-specs.md`
- 项目日志: `docs/logs/PROJECT_LOG.md`
- 测试计划: `docs/testing/2026-03-05-v1.2-full-automation-regression-plan.md`
- CI 回归门禁: `.github/workflows/regression.yml`

### v1.3（进行中）
已完成首批开发，当前处于“细节对齐 + 回归稳定化”阶段：
- 列表语义：已改为“仅展示目标目录已安装项”，不再回退显示来源扫描结果，确保应用列表语义准确。
- 验收修复：已支持嵌套符号链接目录扫描，修复已安装技能列表为空问题。
- 交互语义：已落地“移除 / 清空全部”操作链路。
- 执行链路：已接入 Git clone/pull 后台异步与进行中提示，不阻塞主交互。
- 体验收口：应用切换按 click 驱动，保留轻量转场；设置页持续收敛主题相关能力。
- 状态反馈：已补齐同步中提示、来源错误强调与全局 Toast（右下角，分级时长）。
- 自动化覆盖：已补齐 Toast/来源错误态 UI 自动化断言，并扩展 v1.3 状态快照采集。
- 视觉基线：已完成新增状态快照归档与基线入库，当前 visual diff 可覆盖 6 张快照并稳定通过。
- 回归流程：已新增 `tools/visual-regression/run_visual_gate.py`，统一“采集→归档→diff”为单命令，并接入回归 workflow。
- 视觉稳定化：已在视觉采集用例接入前台激活与窗口就绪检查，修正 `app-target-claudeCode` 入口标识，视觉采集链路通过。
- 视觉门禁收敛：已切换窗口级截图并引入 `max-diff-ratio=0.003` 容差，full gate 本地复跑恢复绿灯（6 snapshots）。
- 回归抗抖动：`run_visual_gate.py` 已支持采集重试、失败退避、进程清理与启动失败类型识别，可在 XCTest Runner 出现 `before establishing connection`/`never finished bootstrapping` 类错误时通过多轮重试自动恢复。
- 启动预热与分层门禁：visual gate 在连续失败时会自动执行 `build-for-testing` 预热并切换 `test-without-building`，并重点覆盖 `VisualSnapshotCaptureUITests/testCaptureV13StateSnapshots` 这一 v1.3 状态快照用例，降低历史用例对门禁稳定性的干扰。
- 验收修复：一键同步新增/移除提示已按目标目录真实差量计算；删除/清空后列表刷新已同步落盘结果。
- 下次续做入口：在 CI runner 观察多轮 `python3 tools/visual-regression/run_visual_gate.py` 结果，若仍出现连续启动失败，再按云端日志继续优化识别文案或拆分门禁粒度。

- PRD: `docs/prd/PRD-004.md`
- v1.3 技术方案: `docs/plans/2026-03-05-skill-dock-v1.3-technical-design-and-plan.md`
- 项目日志: `docs/logs/PROJECT_LOG.md`

### 项目进度

- **已完成**: Task 1-9 (v1.0)
- **已完成**: v1.1 核心 UI 改版与权限同步
- **已完成**: v1.2 多应用管理、Git 来源管理、UI 细节对齐与自动化回归门禁
- **进行中**: v1.3 细节对齐与回归稳定化（UI 全状态补齐、测试链路稳态）

### 最新里程碑（摘要）

- **2026-03-05**: 完成 v1.2 全量功能开发：多应用切换、Git 来源管理、一键同步按应用生效、去项目化收口。
- **2026-03-05**: 完成 6 项高优先级 UI 差异修正：移除多余目录、调整侧边栏顺序、重构来源管理布局、添加切换动画。
- **2026-03-05**: 完成自动化回归体系建设：新增视觉快照测试、修正单元测试、配置 GitHub Actions CI 门禁。
- **2026-03-05**: 完成全链路测试验证：视觉快照测试通过，业务逻辑单元测试 100% 通过。
- **2026-03-05**: v1.3 首批开发完成：已安装视角、移除/清空、Git 后台异步与进度提示已落地。
- **2026-03-05**: 回归验证完成构建与核心单测通过；全量测试存在 runner 波动，进入稳定化处理。
- **2026-03-05**: v1.3 第二批对齐完成：同步中状态条、空态引导、副作用反馈 Toast、来源错误态强化与搜索焦点态落地。
- **2026-03-06**: v1.3 自动化补齐完成：新增 Toast/来源错误态 UI 用例与状态快照扩展，分组回归通过。
- **2026-03-06**: v1.3 视觉基线复核完成：新增状态快照已归档入基线，像素 diff 通过（6 snapshots）。
- **2026-03-06**: v1.3 视觉回归脚本化完成：CI 视觉门禁切换为单命令入口（run_visual_gate.py）。
- **2026-03-06**: v1.3 视觉采集稳态增强：前台激活/窗口就绪检查与入口标识修正已落地，视觉采集测试 2/2 通过。
- **2026-03-06**: v1.3 视觉门禁抖动收敛：窗口级截图 + 0.003 容差阈值落地，visual gate 全链路通过（6 snapshots）。
- **2026-03-06**: v1.3 门禁抗抖动增强：visual gate 增加采集重试、失败退避、进程清理与固定 destination，连续回归可自动恢复。
- **2026-03-06**: v1.3 验收修复完成：已安装目录支持嵌套符号链接扫描，列表不再为空。

### v1.2 设计方案要点

#### 架构变更
- **移除项目功能**：取消"全部项目"和"常用项目"，改为纯全局应用级别管理
- **多应用支持**：支持 Claude Code、Codex、OpenCode、Trae、Trae CN 五个应用
- **独立页面**：来源管理和设置为独立页面（非弹窗）

#### UI 布局
- 左侧：应用列表（click 切换）+ 来源/设置入口
- 右侧：当前应用的 Skills 列表 + 一键同步按钮
- 顶部：Logo + 搜索框

#### 功能特性
- **一键同步**：每个应用界面有同步按钮
- **来源管理**：本地目录 + Git 仓库来源
- **Git 一键更新**：批量更新所有 Git 仓库来源
- **同步策略**：符号链接优先，失败时显示错误（不回退复制）

#### v1.2 技术约束
- **UI 规范**：`docs/specs/v1.2-ui-specs.md`
- **调研报告**：`/Users/mac/Documents/CodingPlace/SkillDock/v1.2/skill-permission-test-report.md`
- 各应用 Skills 目录：
  - Claude Code: `~/.claude/skills`
  - Codex: `~/.codex/skills`
  - OpenCode: `~/.config/opencode/skills`
  - Trae: `~/.trae/skills`
  - Trae CN: `~/.trae-cn/skills`

- **2026-02-28**: 完成全量重命名至 `SkillDock`，并修复测试链路。
- **2026-02-28**: 完成 Task 4（来源目录管理 + 扫描展示）可用闭环。
- **2026-02-28**: 完成方案修订，移除应用列表维度，统一为全局技能开关。
- **2026-03-02**: 完成 Task 6（项目管理 + `.skills-config.json` 项目级配置 + 收藏上限）。
- **2026-03-02**: 完成 Task 7（详情页 + Finder 打开 + 搜索筛选 + 过滤测试）。
- **2026-03-02**: 完成 Task 8（一键同步 + 同名冲突检测 + 四种冲突策略处理）。
- **2026-03-02**: 完成 Task 9（全量回归 + 手工验收清单 + 运行说明收口）。
- **2026-03-02**: 全量 Build/Test 验证通过（详见 `docs/logs/PROJECT_LOG.md`）。
- **2026-03-03**: 完成 v1.1 设计探索（UI 改版 + Skill 开关生效方案）。
- **2026-03-04**: 完成 v1.1 核心能力落地（目录选择器、递归扫描、默认全局目录、`.claude/settings.json` 权限同步）。
- **2026-03-04**: 完成 UI 第一轮结构对齐（顶栏/侧栏/分层内容区/卡片与筛选器样式调整），进入第二轮细节打磨。
- **2026-03-04**: 调整约束方案为纯文档约束（移除 DesignTokens.swift，所有设计值直接在 `docs/specs/v1.1-ui-specs.md` 中定义）。
- **2026-03-04**: 修复 Claude permissions 前缀写入为 `Skills:`，并兼容历史 `skills:` 配置自动归一化。

### 已实现模块（当前有效）

- ✅ 核心数据模型（Skill、Source、AppConfig）
- ✅ 元数据解析与目录扫描（`SkillMetadataParser` + `SkillScanner`）
- ✅ 配置持久化（`ConfigManager`，UserDefaults）
- ✅ 主状态管理（`MainViewModel`，多应用切换 + 全局开关）
- ✅ 来源管理（本地来源 + Git 来源新增/更新/可用性回写）
- ✅ 设置页能力（主题三态 + 目录快捷动作）
- ✅ 一键同步与冲突处理（符号链接优先 + 冲突预览 + 批量策略）
- ✅ 同步异常可视化（结构化 Banner + 复制详情 + 导出日志）
- ✅ 回归测试体系（`AppConfig`/`MainViewModel*`/`SyncFlow`/`UITransformation`）

### 历史能力归档

- v1.0/v1.1 阶段的“项目管理 / 项目级 `.skills-config.json` / 常用项目入口”已下线，仅保留历史记录用于追溯。
- 历史方案请按归档资料阅读，不作为当前实现依据：`docs/prd/PRD-001.md`、`docs/prd/PRD-002.md`、`docs/plans/2026-02-27-skill-dock-v1-design.md`、`docs/plans/2026-02-27-skill-dock-v1-implementation.md`。

## 构建命令

```bash
# 生成 Xcode 项目（修改 project.yml 后必须运行）
xcodegen generate

# 构建
xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build

# 运行全部测试
xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock

# 运行单个测试类
xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests
```

**重要**: 本项目使用 XcodeGen 生成 Xcode 项目。修改 `project.yml` 后必须运行 `xcodegen generate` 才能使更改生效。不要直接修改 `SkillDock.xcodeproj` 文件。

## 运行说明

- 手工验收清单：`docs/testing/manual-v1-checklist.md`
- 全量测试命令：`xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`
- 构建命令：`xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`

## 配置路径

- 应用级配置（UserDefaults key）：`skilldock.appConfig`
- 主要来源目录由用户在 UI 中维护（v1.3 已移除来源数量上限）

## 技术架构

```
View Layer (SwiftUI)
    ↓
ViewModel Layer (ObservableObject)
    ↓
Service Layer (文件系统操作)
    ↓
Model Layer (数据模型)
```

- **MVVM 架构**: SwiftUI 视图 + ObservableObject ViewModel
- **数据持久化**: UserDefaults (应用配置)
- **异步处理**: Swift 5.5+ async/await
- **无第三方依赖**: 纯 SwiftUI + Foundation

### 核心服务类

| 服务 | 文件 | 职责 |
|------|------|------|
| SkillMetadataParser | Services/SkillMetadataParser.swift | 解析 SKILL.md 的 YAML frontmatter |
| SkillScanner | Services/SkillScanner.swift | 扫描目录发现 skill，调用 Parser 解析元数据 |
| FileService | Services/FileService.swift | 文件系统操作（目录存在、读写、Finder reveal） |
| ConfigManager | Services/ConfigManager.swift | AppConfig 配置读写（UserDefaults）与兼容迁移 |

### 关键架构决策

**全局启用状态**：
- 全局状态：`AppConfig.skillStates: [String: Bool]`（存储在 UserDefaults）
- 激活逻辑：始终使用全局状态，按所选应用目录执行同步落盘

**Skill ID 生成规则**：
- 格式：`"{sourcePath}#{folderName}"`
- 目的：确保跨扫描周期稳定识别同一 skill
- 示例：`"/Users/skill#brainstorming"`

**同步冲突处理**：
- 冲突定义：同一 `folderName` 来自不同来源路径，或同一来源下存在重复
- 四种策略：保留旧的 / 替换为新的 / 全部保留旧的 / 全部用新的
- 批量处理：不支持逐条冲突逐项处理

## 数据模型

| 模型 | 文件 | 说明 |
|------|------|------|
| Skill | Models/Skill.swift | skill 目录，id = `sourcePath#folderName`，name/description 从 SKILL.md 解析 |
| Source | Models/Source.swift | 来源目录，包含 id、path、displayName、isBuiltIn |
| AppConfig | Models/AppConfig.swift | 应用配置，包含 sources/selectedApp/selectedPage/themeMode/skillStates |
| SkillMetadata | Services/SkillMetadataParser.swift | 解析结果，包含 name、description |

**Skill ID 规则**: `Skill.makeID(sourcePath:folderName:)` 生成 `"path#folderName"` 格式 ID，确保跨扫描稳定识别。

**description 回落逻辑**: 当 SKILL.md 的 description 为空时，自动使用 `"暂无描述"`（在 Skill init 和 SkillMetadataParser 中双重处理）。

## 目录结构

```
SkillDock/
├── App/           # 入口：SkillDockApp.swift, ContentView.swift
├── Models/        # 数据模型
├── ViewModels/    # MainViewModel
├── Views/         # SwiftUI 视图（Detail/ 等子目录）
├── Services/      # 扫描、解析、配置服务
└── Utils/         # Constants.swift

SkillDockTests/
├── Models/        # AppConfigTests.swift
├── ViewModels/    # MainViewModelSourcesTests.swift, MainViewModelToggleTests.swift, ProjectsFlowTests.swift, SkillFilterTests.swift, SyncFlowTests.swift
└── Services/      # SkillMetadataParserTests.swift, SkillScannerTests.swift
```

## 开发流程

采用 TDD：先写失败测试，再实现最小代码使测试通过。详见 `docs/plans/2026-02-27-skill-dock-v1-implementation.md` 的 Task 划分。

### v1.1 UI 实现注意事项

- UI 规范位于 `docs/specs/v1.1-ui-specs.md`
- 采用**纯文档约束**：所有设计值（颜色、间距、圆角等）直接在规范文档中定义
- **不要**创建 DesignTokens.swift 或类似的设计常量文件
- 实现时直接使用规范中的具体值（如 `Color(hex: "#4c6ef5")`、圆角 `14px` 等）
- 必须覆盖全部状态：正常、加载、空、错误、部分可用

## 业务规则

- **默认 description**: "暂无描述"（在 SkillMetadataParser.parse 中处理）
- **Skill 排序**: 按名称 localizedCaseInsensitiveCompare 升序排列（SkillScanner.scanDirectory 中实现）

## 已知限制（V1）

- 来源与项目目录已支持系统目录选择器，但来源管理交互仍可继续优化（如批量导入、排序）。
- 冲突处理采用批量策略，暂不支持逐条冲突逐项处理。
- 同步结果目前通过状态文本提示，尚未独立实现 Toast 组件。
- 全量测试命令在部分环境存在 runner 波动，建议保留分组执行与失败复检策略。

## 历史方案说明

- v1.1 设计文档与 UI 规范中出现的“项目入口/项目级隔离”属于历史方案，不代表当前实现。
- 需要追溯背景时请结合 `docs/logs/PROJECT_LOG.md` 的时间线阅读，当前实现以“多应用 + 全局状态 + 同步落盘”为准。

## UI 设计原则

- 使用标准 macOS 窗口边框（非自定义标题栏）
- 侧边栏采用入口式导航（应用列表 + 来源管理 + 设置）
- v1.1 UI 规范：`docs/specs/v1.1-ui-specs.md`（纯文档约束，无 DesignTokens 代码）
- 技能卡片：显示名称、描述、全局启用 toggle 开关、详情按钮

## SKILL.md 格式要求

支持的 frontmatter 字段：
```yaml
---
name: "技能名称"
description: "技能描述"
---
```

- `name` 可选，缺失时使用文件夹名
- `description` 可选，缺失或空时使用"暂无描述"
- 值可用双引号或单引号包裹，也可不使用引号
