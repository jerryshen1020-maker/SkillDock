# SkillDock V1.2 技术设计与实施方案

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在现有 v1.1 基础上完成 v1.2 架构升级：移除项目维度，支持 5 个 AI 应用的全局 Skill 管理，并落地来源管理（本地 + Git）与符号链接同步。

**Architecture:** 维持 SwiftUI + MVVM，重构 `MainViewModel` 状态模型为“页面 + 应用”双轴导航；以来源目录作为 SSOT，按应用目录执行符号链接同步与删除；通过配置迁移兼容 v1.1 存量数据。

**Tech Stack:** Swift 5.9, SwiftUI, Foundation, AppKit(NSOpenPanel), XcodeGen, XCTest

---

## 一、输入依据（已对齐）

- PRD：`docs/prd/PRD-003.md`
- UI 规范：`docs/specs/v1.2-ui-specs.md`
- 设计稿：`设计/v1.2-SkillDock/01-设计稿.html`
- 全状态参考：`设计/v1.2-SkillDock/02-全状态设计参考.html`
- 需求总结：`设计/v1.2-SkillDock/需求总结.md`
- 调研结论：`/Users/mac/Documents/CodingPlace/SkillDock/v1.2/skill-permission-test-report.md`

---

## 二、范围与边界

## In Scope（v1.2）

- 多应用管理：Claude Code / Codex / OpenCode / Trae / Trae CN
- 左侧应用列表切换 + 底部来源/设置入口
- Skills 页面：应用维度列表、搜索、删除、一键同步
- 来源页面：本地目录来源 + Git 仓库来源管理
- Git 一键更新：批量 pull 所有 Git 来源
- 设置页面：版本展示 + 主题模式（跟随系统/浅色/深色）
- 同步策略：仅符号链接；失败仅报错，不做复制回退

## Out of Scope（v1.2）

- 项目级别控制与项目管理（全部项目/常用项目）
- Skill 启用/禁用开关（改为“存在即启用，删除即禁用”）
- 复制同步兜底

---

## 三、现状差距（v1.1 -> v1.2）

- 导航仍包含项目页（`favoriteProjects`/`allProjects`），不符合 v1.2
- `AppConfig` 仍持有项目字段与项目级状态
- 同步能力聚焦“来源扫描 + 冲突策略”，缺少“按应用目录落盘同步”
- 来源管理缺少 Git 仓库来源生命周期（clone/pull/remove）
- 设置页为占位态，未包含主题设置

---

## 四、目标架构设计

## 4.1 核心模型重构

### 新增模型

- `Models/AppTarget.swift`
  - `enum AppTarget: String, CaseIterable, Codable`
  - 内置目录映射：
    - Claude: `~/.claude/skills`
    - Codex: `~/.codex/skills`
    - OpenCode: `~/.config/opencode/skills`
    - Trae: `~/.trae/skills`
    - TraeCN: `~/.trae-cn/skills`
- `Models/SourceType.swift`
  - `enum SourceType: String, Codable { case local, git }`
- `Models/GitSource.swift`
  - `id / repoURL / branch / localPath / lastSyncedAt / status`
- `Models/ThemeMode.swift`
  - `system / light / dark`

### 调整现有模型

- `Models/AppConfig.swift`
  - 移除：`projects`、`selectedProjectID`、`skillStates`
  - 新增：
    - `selectedApp: AppTarget`
    - `selectedPage: NavigationPage`
    - `themeMode: ThemeMode`
    - `sources: [Source]`（扩展字段支持本地/Git）
- `Models/Source.swift`
  - 增加：`type`、`repoURL`、`branch`、`isAvailable`、`lastError`

## 4.2 配置迁移策略

- `Services/ConfigManager.swift` 增加迁移入口：
  - 读取旧版配置时，自动丢弃项目字段并映射到 v1.2 字段
  - 默认 `selectedApp = .claude`, `selectedPage = .skills`, `themeMode = .system`
  - 保留已有来源目录，补齐 `Source.type = .local`
- 迁移失败策略：回退默认配置并给出可读错误消息

## 4.3 服务层拆分

- `Services/AppDirectoryService.swift`
  - 解析应用 skills 目录
  - 确保目录存在（必要时创建）
- `Services/AppSyncService.swift`
  - `syncApp(target: AppTarget, skills: [Skill])`
  - `removeSkillFromApp(target: AppTarget, folderName: String)`
  - 仅符号链接；失败返回结构化错误
- `Services/GitSourceService.swift`
  - `clone(repoURL:branch:destination:)`
  - `pull(localPath:)`
  - `validateGitURL(_:)`
- `Services/SourceHealthService.swift`
  - 检查来源可访问性
  - 产出目录不存在/权限不足状态

## 4.4 ViewModel 设计

- 以 `MainViewModel` 为编排层，移除项目相关状态与方法
- 新状态：
  - `selectedApp: AppTarget`
  - `selectedPage: NavigationPage`（skills/source/settings）
  - `skillsByApp: [AppTarget: [Skill]]`
  - `isLoading / isSyncing / toastQueue`
- 新方法：
  - `switchApp(_:)`
  - `syncCurrentApp()`
  - `deleteSkill(_:)`
  - `addLocalSource() / addGitSource() / refreshGitSources()`
  - `setThemeMode(_:)`

## 4.5 UI 结构落位

- `App/ContentView.swift`
  - 保持 `TitleBar + Sidebar + Content`，移除项目页分支
- `Views/Sidebar/SidebarView.swift`
  - 上半区应用列表（5项）
  - 下半区来源/设置入口
- `Views/Content/SkillsRepositoryView.swift`
  - 标题动态显示当前应用
  - 一键同步按钮与搜索联动
  - 卡片提供删除动作
- `Views/Content/SourceManagementView.swift`（新增）
  - 本地来源区 + Git 来源区
  - “+ 添加目录”“+ 添加仓库”“↻ 一键更新”
- `Views/Content/SettingsView.swift`
  - 版本展示 + 主题单选
- 新增组件：
  - `Views/Components/AddLocalSourceModalView.swift`
  - `Views/Components/AddGitSourceModalView.swift`
  - `Views/Components/ToastView.swift`

---

## 五、关键流程设计

## 5.1 应用切换

1. 用户 hover/click 应用项
2. 更新 `selectedApp`
3. 拉取 `skillsByApp[selectedApp]`
4. 刷新 header 标题与统计

## 5.2 一键同步（当前应用）

1. 从所有有效来源扫描技能
2. 为当前应用构建目标路径映射
3. 执行符号链接同步（创建/更新/清理）
4. 输出 Toast：成功/失败（含失败原因）

## 5.3 删除 Skill

1. 在当前应用目录删除对应目录或符号链接
2. 不删除 SSOT 来源文件
3. 更新当前应用列表并给出成功提示

## 5.4 Git 一键更新

1. 遍历 Git 来源执行 pull
2. 收集成功/失败计数与错误详情
3. 完成后触发当前应用重扫与同步建议

---

## 六、实施计划（最新）

## Task 1：模型与配置迁移

**Files**
- Create: `SkillDock/Models/AppTarget.swift`
- Create: `SkillDock/Models/ThemeMode.swift`
- Modify: `SkillDock/Models/Source.swift`
- Modify: `SkillDock/Models/AppConfig.swift`
- Modify: `SkillDock/Services/ConfigManager.swift`
- Test: `SkillDockTests/Models/AppConfigTests.swift`

**完成标准**
- 启动可无损加载旧配置并迁移到 v1.2 结构
- 迁移后保存与再次加载结果一致

## Task 2：移除项目逻辑并重建导航状态

**Files**
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Modify: `SkillDock/App/ContentView.swift`
- Modify: `SkillDock/Views/Sidebar/SidebarView.swift`
- Delete logic: `selectedProject` 相关方法与调用链
- Test: `SkillDockTests/ViewModels/UITransformationTests.swift`

**完成标准**
- 侧栏仅保留 5 个应用 + 来源 + 设置
- 运行期不再读写 `.skills-config.json`

## Task 3：应用目录同步能力（Symlink Only）

**Files**
- Create: `SkillDock/Services/AppDirectoryService.swift`
- Create: `SkillDock/Services/AppSyncService.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/Services/AppSyncServiceTests.swift`
- Test: `SkillDockTests/ViewModels/SyncFlowTests.swift`

**完成标准**
- 当前应用一键同步可创建/更新符号链接
- 同步失败可返回明确错误，不做 copy fallback

## Task 4：来源管理页 + Git 来源能力

**Files**
- Create: `SkillDock/Services/GitSourceService.swift`
- Create: `SkillDock/Views/Content/SourceManagementView.swift`
- Create: `SkillDock/Views/Components/AddGitSourceModalView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/MainViewModelSourcesTests.swift`
- Test: `SkillDockTests/Services/GitSourceServiceTests.swift`

**完成标准**
- 可添加/删除本地来源
- 可添加 Git 来源并克隆
- 可一键更新 Git 来源并得到聚合结果

## Task 5：Skills 页与删除交互升级

**Files**
- Modify: `SkillDock/Views/Content/SkillsRepositoryView.swift`
- Modify: `SkillDock/Views/Components/SkillCardView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/SkillFilterTests.swift`

**完成标准**
- Skills 卡片展示名称/描述/来源并支持删除
- 搜索过滤覆盖名称/描述/来源路径

## Task 6：设置页与主题切换

**Files**
- Modify: `SkillDock/Views/Content/SettingsView.swift`
- Modify: `SkillDock/App/SkillDockApp.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/UITransformationTests.swift`

**完成标准**
- 支持 system/light/dark 主题
- 主题配置持久化并在重启后恢复

## Task 7：状态反馈与回归收口

**Files**
- Create: `SkillDock/Models/ToastMessage.swift`
- Create: `SkillDock/Views/Components/ToastView.swift`
- Modify: `SkillDock/App/ContentView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/SyncFlowTests.swift`

**完成标准**
- 覆盖加载/空态/错误态/成功态
- Toast 时长与数量符合 `docs/specs/v1.2-ui-specs.md`

---

## 七、测试与验收策略

- 单测优先覆盖：
  - 配置迁移（v1.1 -> v1.2）
  - App 目录同步（创建/覆盖/删除/失败）
  - Git 来源（URL 校验、clone、pull 失败分支）
  - 搜索与页面切换状态
- 构建与测试命令：
  - `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
  - `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`
- 手工验收对齐：
  - `docs/prd/PRD-003.md` 第 7 节
  - `docs/specs/v1.2-ui-specs.md` 第 12 节

---

## 八、风险与应对

- **测试 Runner 仍可能 hang**：保留 build-for-testing / test-without-building 兜底链路
- **Git 命令依赖本机环境**：在 UI 层暴露失败原因并支持重试
- **符号链接权限差异**：目录不可写时直接报错，不做隐式降级

---

## 九、里程碑建议

- M1：模型迁移 + 新导航（可运行）
- M2：应用同步 + Skills 删除（核心闭环）
- M3：来源管理 + Git 更新（扩展能力）
- M4：设置/主题 + 全状态反馈 + 回归发布

