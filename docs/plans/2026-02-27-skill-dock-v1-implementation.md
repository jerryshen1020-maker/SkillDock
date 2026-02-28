# SkillDock V1.0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 交付 SkillDock V1 完整功能：多来源 skill 扫描管理、项目级隔离配置、搜索筛选、详情查看与一键同步。

**Architecture:** 采用 MVVM，`MainViewModel` 作为聚合状态入口，`Services` 负责扫描与配置读写，`Views` 仅做展示和交互。按纵向切片实现，每个切片可独立运行与验收。

**Tech Stack:** Swift 5.9, SwiftUI, Combine, Foundation, XcodeGen, XCTest

---

### Task 1: 初始化工程与基础目录

**Files:**
- Create: `project.yml`
- Create: `SkillDock/App/SkillDockApp.swift`
- Create: `SkillDock/App/ContentView.swift`
- Create: `SkillDock/Utils/Constants.swift`

**Step 1: 生成最小工程配置**
- 在 `project.yml` 定义 macOS App target、deployment target 12.0、主模块 `SkillDock`、测试 target `SkillDockTests`。

**Step 2: 生成项目文件**
- Run: `xcodegen generate`
- Expected: 生成 `SkillDock.xcodeproj`

**Step 3: 写最小 App 入口与占位主视图**
- 在 `SkillDockApp.swift` 注入 `MainViewModel`。
- 在 `ContentView.swift` 放置左右分栏占位。

**Step 4: 首次构建验证**
- Run: `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: BUILD SUCCEEDED

**Step 5: Commit**
- `git add project.yml SkillDock/App SkillDock/Utils`
- `git commit -m "chore: bootstrap SkillDock app skeleton"`

### Task 2: 建立核心模型与配置结构

**Files:**
- Create: `SkillDock/Models/Skill.swift`
- Create: `SkillDock/Models/Source.swift`
- Create: `SkillDock/Models/Project.swift`
- Create: `SkillDock/Models/AppConfig.swift`
- Create: `SkillDock/Models/ProjectSkillConfig.swift`
- Test: `SkillDockTests/Models/AppConfigTests.swift`

**Step 1: 写失败测试（编解码与默认值）**
- 覆盖 `AppConfig`/`ProjectSkillConfig` 编码解码与默认字段。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests`
- Expected: FAIL（模型未实现）

**Step 3: 最小实现模型**
- `Codable` + `Equatable` + 必要默认构造。
- `Skill.id` 使用 `sourcePath + folderName` 计算规则。

**Step 4: 重新测试**
- Run: 同上
- Expected: PASS

**Step 5: Commit**
- `git add SkillDock/Models SkillDockTests/Models`
- `git commit -m "feat: add core models and config schemas"`

### Task 3: 实现元数据解析与目录扫描（US-02）

**Files:**
- Create: `SkillDock/Services/SkillMetadataParser.swift`
- Create: `SkillDock/Services/SkillScanner.swift`
- Create: `SkillDock/Services/FileService.swift`
- Test: `SkillDockTests/Services/SkillMetadataParserTests.swift`
- Test: `SkillDockTests/Services/SkillScannerTests.swift`

**Step 1: 写失败测试**
- frontmatter `name/description` 解析。
- 缺失 `SKILL.md` 跳过。
- description 为空回落“暂无描述”。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillMetadataParserTests -only-testing:SkillDockTests/SkillScannerTests`
- Expected: FAIL

**Step 3: 实现 parser 与 scanner**
- scanner 遍历一级子目录，识别包含 `SKILL.md` 的目录。
- parser 解析 frontmatter，异常时返回可恢复错误。

**Step 4: 重新测试**
- Run: 同上
- Expected: PASS

**Step 5: Commit**
- `git add SkillDock/Services SkillDockTests/Services`
- `git commit -m "feat: implement skill metadata parser and scanner"`

### Task 4: 来源目录管理与扫描展示（US-01/03）

**Files:**
- Create: `SkillDock/ViewModels/MainViewModel.swift`
- Create: `SkillDock/Services/ConfigManager.swift`
- Create: `SkillDock/Views/Sidebar/SourcesSectionView.swift`
- Create: `SkillDock/Views/Content/SkillsListView.swift`
- Modify: `SkillDock/App/ContentView.swift`
- Test: `SkillDockTests/ViewModels/MainViewModelSourcesTests.swift`

**Step 1: 写失败测试**
- 添加来源（去重、上限 10）。
- 删除来源后技能列表刷新。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests`
- Expected: FAIL

**Step 3: 最小实现**
- `MainViewModel` 暴露 `sources/skills/errors`。
- `ConfigManager` 落盘来源配置到 UserDefaults。
- UI 增加来源区和技能列表基础展示。

**Step 4: 重新测试 + 构建**
- Run: 上述 test + `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: PASS + BUILD SUCCEEDED

**Step 5: Commit**
- `git add SkillDock/ViewModels SkillDock/Views SkillDock/Services/ConfigManager.swift SkillDockTests/ViewModels`
- `git commit -m "feat: add source management and skill listing"`

### Task 5: 全局启用/禁用与应用维度配置（US-06）

**Files:**
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Modify: `SkillDock/Models/AppConfig.swift`
- Modify: `SkillDock/Views/Content/SkillsListView.swift`
- Create: `SkillDock/Views/Content/AppTargetPickerView.swift`
- Test: `SkillDockTests/ViewModels/MainViewModelToggleTests.swift`

**Step 1: 写失败测试**
- 切换启用状态后持久化。
- 切换 app target 后读取对应状态。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelToggleTests`
- Expected: FAIL

**Step 3: 最小实现**
- 新增 `AppTarget` 枚举。
- `skills` 状态按 `appTarget + skillID` 存储。
- 列表行加入 toggle。

**Step 4: 重新测试**
- Run: 同上
- Expected: PASS

**Step 5: Commit**
- `git add SkillDock/Models SkillDock/ViewModels SkillDock/Views SkillDockTests/ViewModels`
- `git commit -m "feat: support app-scoped skill enable toggles"`

### Task 6: 项目管理与项目级配置（US-08/09/10/11）

**Files:**
- Create: `SkillDock/ViewModels/ProjectsViewModel.swift`
- Create: `SkillDock/Views/Sidebar/FavoriteProjectsView.swift`
- Create: `SkillDock/Views/Sidebar/AllProjectsView.swift`
- Modify: `SkillDock/Services/ConfigManager.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/ProjectsFlowTests.swift`

**Step 1: 写失败测试**
- 添加项目、切换项目、写入 `.skills-config.json`。
- 收藏上限 5。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/ProjectsFlowTests`
- Expected: FAIL

**Step 3: 最小实现**
- 添加/切换/收藏项目。
- 项目目录下读写 `.skills-config.json`。
- 侧边栏展示“常用项目/全部项目”。

**Step 4: 重新测试**
- Run: 同上
- Expected: PASS

**Step 5: Commit**
- `git add SkillDock/ViewModels SkillDock/Views/Sidebar SkillDock/Services SkillDockTests/ViewModels`
- `git commit -m "feat: add project management and project-scoped config"`

### Task 7: 详情页、Finder 打开、搜索筛选（US-04/12）

**Files:**
- Create: `SkillDock/Views/Detail/SkillDetailView.swift`
- Create: `SkillDock/Views/Content/SearchBarView.swift`
- Modify: `SkillDock/Views/Content/SkillsListView.swift`
- Modify: `SkillDock/Services/FileService.swift`
- Test: `SkillDockTests/ViewModels/SkillFilterTests.swift`

**Step 1: 写失败测试**
- 名称 + description 模糊搜索。
- 来源筛选与关键词 AND 关系。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillFilterTests`
- Expected: FAIL

**Step 3: 最小实现**
- 搜索框 + 来源筛选器。
- 详情页展示 metadata，支持 Finder 打开目录。

**Step 4: 重新测试 + 构建**
- Run: 上述 test + `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: PASS + BUILD SUCCEEDED

**Step 5: Commit**
- `git add SkillDock/Views SkillDock/Services/FileService.swift SkillDockTests/ViewModels`
- `git commit -m "feat: add skill detail and search/filter"`

### Task 8: 一键同步与冲突处理（US-14）

**Files:**
- Create: `SkillDock/Components/ConfirmDialog.swift`
- Create: `SkillDock/Components/ToastView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Modify: `SkillDock/Views/Content/SkillsListView.swift`
- Test: `SkillDockTests/ViewModels/SyncFlowTests.swift`

**Step 1: 写失败测试**
- 同步 diff（新增/删除/冲突）。
- 冲突策略（保留旧/替换新/批量策略）行为正确。

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SyncFlowTests`
- Expected: FAIL

**Step 3: 最小实现**
- 同步按钮触发重扫。
- 冲突弹窗 + 处理策略。
- Toast 显示同步结果摘要。

**Step 4: 重新测试**
- Run: 同上
- Expected: PASS

**Step 5: Commit**
- `git add SkillDock/ViewModels SkillDock/Views SkillDock/Components SkillDockTests/ViewModels`
- `git commit -m "feat: implement one-click sync and conflict resolution"`

### Task 9: 回归与文档收口

**Files:**
- Modify: `SkillDock/CLAUDE.md`
- Create: `SkillDock/docs/testing/manual-v1-checklist.md`

**Step 1: 写手工验收 checklist**
- 覆盖 PRD 对应用户故事与异常分支。

**Step 2: 执行完整测试**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`
- Expected: TEST SUCCEEDED

**Step 3: 执行构建验证**
- Run: `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: BUILD SUCCEEDED

**Step 4: 更新开发说明**
- 补充运行命令、配置路径、已知限制。

**Step 5: Commit**
- `git add SkillDock/CLAUDE.md SkillDock/docs/testing/manual-v1-checklist.md`
- `git commit -m "docs: add V1 test checklist and runbook"`
