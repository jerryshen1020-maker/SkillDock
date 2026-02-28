# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

- **名称**: SkillsManager
- **类型**: macOS 原生应用 (SwiftUI)
- **目的**: 统一管理 AI 工具的 skill，支持按应用和项目隔离配置
- **兼容性**: macOS 12.0+

## 当前状态

Tasks 1-3 已完成（工程初始化 + 核心模型 + 元数据解析与扫描）。剩余 Tasks 4-9 待实现。

- PRD: `docs/prd/PRD-001.md`
- 实现计划: `docs/plans/2026-02-27-skills-manager-v1-implementation.md`
- 设计稿: `设计/v1.0-SkillsManager/`

### 已实现模块

- ✅ 核心数据模型（Skill、Source、Project、AppConfig、ProjectSkillConfig）
- ✅ 元数据解析器（SkillMetadataParser）- 解析 SKILL.md 的 YAML frontmatter
- ✅ 目录扫描器（SkillScanner）- 扫描来源目录并发现 skill
- ✅ 基础测试（AppConfig、SkillMetadataParser、SkillScanner）

### 待实现模块

- ⏳ MainViewModel（核心状态管理）
- ⏳ ConfigManager（配置持久化）
- ⏳ SwiftUI 视图层（侧边栏、技能列表、详情页等）
- ⏳ 项目管理与项目级配置
- ⏳ 搜索筛选与同步功能

## 构建命令

```bash
# 生成 Xcode 项目（修改 project.yml 后需运行）
xcodegen generate

# 构建
xcodebuild -project SkillsManager.xcodeproj -scheme SkillsManager build

# 运行全部测试
xcodebuild test -project SkillsManager.xcodeproj -scheme SkillsManager

# 运行单个测试类
xcodebuild test -project SkillsManager.xcodeproj -scheme SkillsManager -only-testing:SkillsManagerTests/AppConfigTests
```

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
- **数据持久化**: UserDefaults (应用配置) + JSON 文件 (项目配置)
- **异步处理**: Swift 5.5+ async/await
- **无第三方依赖**: 纯 SwiftUI + Foundation

### 核心服务类

| 服务 | 文件 | 职责 |
|------|------|------|
| SkillMetadataParser | Services/SkillMetadataParser.swift | 解析 SKILL.md 的 YAML frontmatter |
| SkillScanner | Services/SkillScanner.swift | 扫描目录发现 skill，调用 Parser 解析元数据 |
| FileService | Services/FileService.swift | 文件系统操作（待实现） |
| ConfigManager | Services/ConfigManager.swift | 配置读写（待实现） |

## 数据模型

| 模型 | 文件 | 说明 |
|------|------|------|
| Skill | Models/Skill.swift | skill 目录，id = `sourcePath#folderName`，name/description 从 SKILL.md 解析 |
| Source | Models/Source.swift | 来源目录，包含 id、path、displayName、isBuiltIn |
| Project | Models/Project.swift | 项目，包含 id、path、name、isFavorite、updatedAt |
| AppConfig | Models/AppConfig.swift | 应用配置，包含 sources/projects/selectedProjectID/selectedAppTarget |
| ProjectSkillConfig | Models/ProjectSkillConfig.swift | 项目级配置，存放在项目目录 `.skills-config.json` |
| SkillMetadata | Services/SkillMetadataParser.swift | 解析结果，包含 name、description |

**Skill ID 规则**: `Skill.makeID(sourcePath:folderName:)` 生成 `"path#folderName"` 格式 ID，确保跨扫描稳定识别。

**AppTarget 枚举**: 支持 `claudeCode`、`codex`、`trae`、`traeCN` 四种应用，每种应用独立维护 skill 启用状态。

**description 回落逻辑**: 当 SKILL.md 的 description 为空时，自动使用 `"暂无描述"`（在 Skill init 和 SkillMetadataParser 中双重处理）。

## 目录结构

```
SkillsManager/
├── App/           # 入口：SkillsManagerApp.swift, ContentView.swift
├── Models/        # 数据模型（已实现）
├── ViewModels/    # MainViewModel（骨架）
├── Views/         # SwiftUI 视图（待实现）
├── Services/      # 扫描、解析、配置服务（待实现）
└── Utils/         # Constants.swift

SkillsManagerTests/
└── Models/        # AppConfigTests.swift
```

## 开发流程

采用 TDD：先写失败测试，再实现最小代码使测试通过。详见 `docs/plans/2026-02-27-skills-manager-v1-implementation.md` 的 Task 划分。

## 业务规则

- **来源目录上限**: 10 个
- **收藏项目上限**: 5 个
- **默认 description**: "暂无描述"（在 SkillMetadataParser.parse 中处理）
- **Skill 排序**: 按名称 localizedCaseInsensitiveCompare 升序排列（SkillScanner.scanDirectory 中实现）

## UI 设计原则

- 使用标准 macOS 窗口边框（非自定义标题栏）
- 侧边栏结构：Skills仓库 / 常用项目 / 全部项目
- 右侧顶部：应用切换下拉菜单（Claude Code、Codex、Trae、Trae CN）
- 技能卡片：显示名称、描述、应用维度 toggle 开关、详情按钮

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