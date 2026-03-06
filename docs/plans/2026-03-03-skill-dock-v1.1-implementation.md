# SkillDock V1.1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 V1.0 基础上交付 UX 优化与功能完善：UI 改版、目录选择器、递归扫描、默认全局目录、Skill 开关生效。

**Architecture:** 延续 V1.0 MVVM 架构，新增 UI 组件和服务能力，按纵向切片实现。

**Tech Stack:** Swift 5.9, SwiftUI, Combine, Foundation, XcodeGen, XCTest, AppKit (NSOpenPanel)

---

## 执行进度同步

- ⏳ Task 1 待完成：UI 改版 - 入口式侧边栏 + 现代配色
- ⏳ Task 2 待完成：目录选择器 - NSOpenPanel 集成
- ⏳ Task 3 待完成：递归扫描 - 子目录遍历
- ⏳ Task 4 待完成：默认全局目录 - 自动导入 ~/.claude/skills/
- ⏳ Task 5 待完成：Skill 开关生效 - .claude/settings.json 同步
- ⏳ Task 6 待完成：测试与文档收口

---

## Task 1: UI 改版 - 入口式侧边栏 + 现代配色

**状态**: ⏳ 待完成

**Files:**
- Create: `SkillDock/Views/Sidebar/SidebarView.swift`
- Create: `SkillDock/Views/Sidebar/SidebarEntryView.swift`
- Create: `SkillDock/Views/Content/SkillsRepositoryView.swift`
- Create: `SkillDock/Views/Content/ProjectsView.swift`
- Create: `SkillDock/Views/Content/SettingsView.swift`
- Create: `SkillDock/Views/Components/SkillCardView.swift`
- Create: `SkillDock/Views/Components/SourceFilterView.swift`
- Modify: `SkillDock/App/ContentView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/ViewModels/UITransformationTests.swift`

**Step 1: UI 规范文档已就绪**
- 参考 `docs/specs/v1.1-ui-specs.md` 获取完整设计规范
- 采用纯文档约束方式，无 DesignTokens 代码
- 配色方案、间距、圆角等详见规范文档

**Step 2: 重构侧边栏为入口式**
- 创建 `SidebarView` 作为侧边栏容器
- 创建 `SidebarEntryView` 作为单个入口项
- 实现入口点击切换逻辑
- 支持：Skills 仓库、常用项目、全部项目、设置

**Step 3: 创建内容区视图**
- `SkillsRepositoryView`：Skills 仓库页，包含搜索、来源筛选、技能网格
- `ProjectsView`：项目列表页（复用 v1.0 逻辑）
- `SettingsView`：设置页（占位）

**Step 4: 创建技能卡片组件**
- `SkillCardView`：网格卡片布局
- 包含：图标、名称、路径、描述、Toggle、详情按钮
- 应用现代配色和圆角

**Step 5: 创建来源筛选器组件**
- `SourceFilterView`：水平滚动的来源标签
- 支持选中状态切换
- 显示每个来源的 skill 数量

**Step 6: 更新 MainViewModel**
- 新增 `selectedTab: SidebarTab` 状态
- 新增 `filteredBySource: UUID?` 状态
- 更新 `filteredSkills` 计算逻辑

**Step 7: 更新 ContentView**
- 替换旧侧边栏为 `SidebarView`
- 内容区根据 `selectedTab` 切换视图
- 应用全局配色

**Step 8: 写测试并验证**
- 验证侧边栏入口切换逻辑
- 验证筛选与搜索组合逻辑
- 构建验证：`xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`

**Step 9: Commit**
- `git add SkillDock/Views SkillDock/Utils SkillDock/ViewModels SkillDockTests/ViewModels`
- `git commit -m "feat(v1.1): implement entry-based sidebar and modern UI redesign"`

---

## Task 2: 目录选择器 - NSOpenPanel 集成

**状态**: ⏳ 待完成

**Files:**
- Create: `SkillDock/Services/DirectoryPickerService.swift`
- Create: `SkillDock/Views/Components/DirectoryPicker.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/Services/DirectoryPickerServiceTests.swift`

**Step 1: 写失败测试**
- 验证 NSOpenPanel 调用
- 验证路径有效性检查

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/DirectoryPickerServiceTests`
- Expected: FAIL

**Step 3: 实现 DirectoryPickerService**
```swift
class DirectoryPickerService {
    @MainActor
    func selectDirectory() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        let response = panel.runModal()
        return response == .OK ? panel.url?.path : nil
    }

    func validateDirectory(_ path: String) -> Bool {
        // 检查路径存在、可读、不是已有来源
    }
}
```

**Step 4: 实现 SwiftUI 包装器**
- `DirectoryPicker` 视图组件，触发 NSOpenPanel

**Step 5: 更新 MainViewModel**
- 移除手动路径输入相关逻辑
- 添加 `addSourceFromPicker()` 方法

**Step 6: 更新 UI**
- "添加来源" 按钮改为调用目录选择器
- "添加项目" 按钮改为调用目录选择器

**Step 7: 重新测试 + 构建**
- Run: 上述 test + `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: PASS + BUILD SUCCEEDED

**Step 8: Commit**
- `git add SkillDock/Services SkillDock/Views/Components SkillDock/ViewModels SkillDockTests/Services`
- `git commit -m "feat(v1.1): integrate NSOpenPanel directory picker"`

---

## Task 3: 递归扫描 - 子目录遍历

**状态**: ⏳ 待完成

**Files:**
- Modify: `SkillDock/Services/SkillScanner.swift`
- Test: `SkillDockTests/Services/SkillScannerRecursiveTests.swift`

**Step 1: 写失败测试**
- 递归扫描测试（包含子目录的 mock 目录）
- 符号链接测试
- 权限错误测试

**Step 2: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillScannerRecursiveTests`
- Expected: FAIL

**Step 3: 修改 SkillScanner**
```swift
func scanDirectoryRecursively(_ path: String, sourceID: UUID) throws -> [Skill] {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(
        at: URL(fileURLWithPath: path),
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    ) else {
        throw ScanError.enumerationFailed
    }

    var skills: [Skill] = []
    for case let url as URL in enumerator {
        // 检查是否包含 SKILL.md
        let skillMD = url.appendingPathComponent("SKILL.md")
        if fileManager.fileExists(atPath: skillMD.path) {
            // 解析并添加
        }
    }
    return skills
}
```

**Step 4: 处理边界情况**
- 符号链接检测：跳过或跟随（可选）
- 权限错误：捕获并跳过
- 深度限制：可选（避免过深遍历）

**Step 5: 更新 MainViewModel**
- `addSource` 和 `refreshSkills` 改用递归扫描

**Step 6: 重新测试**
- Run: 同上
- Expected: PASS

**Step 7: Commit**
- `git add SkillDock/Services SkillDockTests/Services`
- `git commit -m "feat(v1.1): implement recursive directory scanning"`

---

## Task 4: 默认全局目录 - 自动导入 ~/.claude/skills/

**状态**: ⏳ 待完成

**Files:**
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Modify: `SkillDock/Models/Source.swift`
- Test: `SkillDockTests/ViewModels/DefaultSourceTests.swift`

**Step 1: 扩展 Source 模型**
```swift
struct Source {
    // ... 现有字段
    var isBuiltIn: Bool  // 内置来源标识
}
```

**Step 2: 写失败测试**
- 验证首次启动自动添加
- 验证内置来源不可删除
- 验证路径存在性检测

**Step 3: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/DefaultSourceTests`
- Expected: FAIL

**Step 4: 实现 MainViewModel 扩展**
```swift
private func ensureDefaultSource() {
    let defaultPath = ("~/.claude/skills/" as NSString).expandingTildeInPath
    guard fileService.directoryExists(defaultPath) else { return }
    guard !sources.contains(where: { $0.isBuiltIn }) else { return }

    let source = Source(
        path: defaultPath,
        displayName: "全局 Skills",
        isBuiltIn: true
    )
    sources.append(source)
    persistAppConfig()
}
```

**Step 5: 在 load() 中调用**
- 启动时调用 `ensureDefaultSource()`

**Step 6: 更新移除逻辑**
- `removeSource` 检查 `isBuiltIn`，内置来源阻止删除

**Step 7: 更新 UI**
- 内置来源显示标识（如"内置"标签）
- 隐藏删除按钮

**Step 8: 重新测试**
- Run: 同上
- Expected: PASS

**Step 9: Commit**
- `git add SkillDock/Models SkillDock/ViewModels SkillDock/Views SkillDockTests/ViewModels`
- `git commit -m "feat(v1.1): auto-import default global skills directory"`

---

## Task 5: Skill 开关生效 - .claude/settings.json 同步

**状态**: ⏳ 待完成

**Files:**
- Create: `SkillDock/Services/ClaudeSettingsService.swift`
- Create: `SkillDock/Models/ToastMessage.swift`
- Create: `SkillDock/Views/Components/ToastView.swift`
- Modify: `SkillDock/ViewModels/MainViewModel.swift`
- Test: `SkillDockTests/Services/ClaudeSettingsServiceTests.swift`
- Test: `SkillDockTests/ViewModels/SkillToggleSyncTests.swift`

**Step 1: 创建 Claude 配置模型**
```swift
struct ClaudePermissions: Codable {
    var allow: Set<String>
    var deny: Set<String>
}
```

**Step 2: 写失败测试（ClaudeSettingsService）**
- 读取不存在的文件返回 nil
- 创建 .claude 目录
- 写入 permissions
- 保留现有其他字段

**Step 3: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/ClaudeSettingsServiceTests`
- Expected: FAIL

**Step 4: 实现 ClaudeSettingsService**
```swift
class ClaudeSettingsService {
    func readPermissions(projectPath: String) -> ClaudePermissions?
    func writePermissions(_ permissions: ClaudePermissions, projectPath: String) -> Bool
    func ensureClaudeDirectory(at projectPath: String) -> Bool
    func updateSkillState(_ skillName: String, enabled: Bool, projectPath: String) -> Bool
}
```

**Step 5: 创建 Toast 系统**
- `ToastMessage` 模型
- `ToastView` 组件
- 在 ContentView 中添加 Toast 容器

**Step 6: 写失败测试（Toggle 同步）**
- Toggle 开启后写入 allow
- Toggle 关闭后写入 deny
- 无项目时仅更新本地配置

**Step 7: 运行测试验证失败**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillToggleSyncTests`
- Expected: FAIL

**Step 8: 更新 MainViewModel**
- 注入 `ClaudeSettingsService`
- `setSkillEnabled` 同时更新 Claude 配置
- 新增 `toastMessages` 状态

**Step 9: 重新测试 + 构建**
- Run: 上述 tests + `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: PASS + BUILD SUCCEEDED

**Step 10: Commit**
- `git add SkillDock/Services SkillDock/Models SkillDock/Views/Components SkillDock/ViewModels SkillDockTests/Services SkillDockTests/ViewModels`
- `git commit -m "feat(v1.1): sync skill toggles to Claude settings.json"`

---

## Task 6: 测试与文档收口

**状态**: ⏳ 待完成

**Files:**
- Modify: `CLAUDE.md`
- Create: `docs/testing/manual-v1.1-checklist.md`
- Modify: `docs/logs/PROJECT_LOG.md`

**Step 1: 写手工验收 checklist**
- UI 改版验收（侧边栏、卡片、配色）
- 目录选择器验收
- 递归扫描验收
- 默认全局目录验收
- Skill 开关生效验收
- Toast 反馈验收

**Step 2: 执行完整测试**
- Run: `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`
- Expected: TEST SUCCEEDED

**Step 3: 执行构建验证**
- Run: `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- Expected: BUILD SUCCEEDED

**Step 4: 更新开发文档**
- 更新 `CLAUDE.md` 当前阶段状态
- 更新 `PROJECT_LOG.md` 记录 v1.1 变更

**Step 5: Commit**
- `git add CLAUDE.md docs/testing docs/logs`
- `git commit -m "docs(v1.1): add test checklist and update documentation"`

---

## 验收标准总览

| 功能 | 验收标准 |
|------|----------|
| UI 改版 | 入口式侧边栏、现代配色、网格卡片、来源筛选器 |
| 目录选择器 | NSOpenPanel 弹窗、路径验证、取消处理 |
| 递归扫描 | 遍历子目录、符号链接处理、权限错误处理 |
| 默认全局目录 | 自动导入 ~/.claude/skills/、内置标识、不可删除 |
| Skill 开关生效 | .claude/settings.json 读写、Toast 反馈 |
| 测试 | 全量单元测试通过、手工验收通过 |
| 文档 | Checklist 完整、CLAUDE.md 更新 |
