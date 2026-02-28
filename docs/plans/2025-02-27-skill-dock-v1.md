# SkillDock V1.0 技术方案

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建 macOS 原生应用，统一管理 AI 工具的 skill，支持按项目隔离配置。

**Architecture:** MVVM 架构，SwiftUI 视图层 + ObservableObject ViewModel + Service 层处理文件系统交互。数据持久化使用 UserDefaults 存储应用配置，JSON 文件存储项目级配置。

**Tech Stack:** Swift 5.9, SwiftUI, macOS 12.0+, Combine, Foundation

---

## 1. 技术栈选型

### 1.1 核心框架

| 组件 | 技术 | 说明 |
|------|------|------|
| UI 框架 | SwiftUI | 原生声明式 UI，macOS 12.0+ |
| 架构模式 | MVVM | 视图与业务逻辑分离 |
| 响应式 | Combine | 数据绑定与事件处理 |
| 数据持久化 | UserDefaults + JSON | 轻量级配置存储 |

### 1.2 最低兼容版本

- **macOS**: 12.0 Monterey
- **Swift**: 5.9
- **Xcode**: 15.0+

### 1.3 第三方依赖

本项目不引入第三方依赖，使用纯原生实现。

---

## 2. 架构设计

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      View Layer (SwiftUI)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ SidebarView │  │ ContentView │  │ SkillDetailView    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    ViewModel Layer (ObservableObject)        │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ SkillsViewModel │  │ ProjectsViewModel│                   │
│  └─────────────────┘  └─────────────────┘                   │
├─────────────────────────────────────────────────────────────┤
│                    Service Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │SkillScanner │  │ConfigManager│  │ FileService         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Model Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Skill    │  │    Source   │  │      Project        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流向

```
User Action → View → ViewModel → Service → Model
                      ↑              ↓
                      └── Published ←┘
```

---

## 3. 数据模型设计

### 3.1 核心模型

#### Skill（技能）

```swift
// Models/Skill.swift
struct Skill: Identifiable, Codable, Hashable {
    let id: String           // skill 目录名（唯一标识）
    let name: String         // 显示名称
    let description: String  // SKILL.md 中的 description
    let sourcePath: String   // 所属来源目录路径
    let fullPath: String     // 完整路径
    var isEnabled: Bool      // 是否启用（全局状态）
}
```

#### Source（来源目录）

```swift
// Models/Source.swift
struct Source: Identifiable, Codable {
    let id: UUID
    let path: String
    let name: String         // 目录名（用于显示）
    let addedAt: Date
    var skillCount: Int      // 该目录下的 skill 数量
}
```

#### Project（项目）

```swift
// Models/Project.swift
struct Project: Identifiable, Codable {
    let id: UUID
    let path: String
    let name: String
    var isFavorite: Bool
    var skills: [String: Bool]  // skill id -> enabled
}
```

### 3.2 配置文件格式

#### 应用配置（UserDefaults 存储）

```swift
// UserDefaults keys
enum ConfigKey {
    static let sources = "skillsmanager.sources"
    static let projects = "skillsmanager.projects"
    static let globalSkills = "skillsmanager.globalSkills"
}
```

#### 项目配置（.skills-config.json）

```json
{
  "version": "1.0",
  "skills": {
    "brainstorming": true,
    "design-exploration": false
  }
}
```

---

## 4. 模块划分

### 4.1 目录结构

```
SkillDock/
├── App/
│   ├── SkillDockApp.swift      // App 入口
│   └── ContentView.swift           // 主视图
├── Models/
│   ├── Skill.swift
│   ├── Source.swift
│   ├── Project.swift
│   └── AppConfig.swift
├── ViewModels/
│   ├── SkillsViewModel.swift
│   ├── ProjectsViewModel.swift
│   └── MainViewModel.swift
├── Services/
│   ├── SkillScanner.swift          // 扫描 skill 目录
│   ├── ConfigManager.swift         // 配置管理
│   ├── FileService.swift           // 文件操作
│   └── SkillMetadataParser.swift   // 解析 SKILL.md
├── Views/
│   ├── Sidebar/
│   │   ├── SidebarView.swift
│   │   ├── SourcesSectionView.swift
│   │   ├── FavoriteProjectsView.swift
│   │   └── AllProjectsView.swift
│   ├── Content/
│   │   ├── SkillsListView.swift
│   │   ├── SkillRowView.swift
│   │   └── SearchBarView.swift
│   └── Detail/
│       └── SkillDetailView.swift
├── Components/
│   ├── ToastView.swift
│   └── ConfirmDialog.swift
└── Utils/
    ├── PathUtils.swift
    └── Constants.swift
```

### 4.2 模块职责

| 模块 | 职责 |
|------|------|
| Models | 数据模型定义， Codable 支持 |
| ViewModels | 业务逻辑，状态管理，数据绑定 |
| Services | 文件系统操作，配置读写，skill 扫描 |
| Views | SwiftUI 视图组件 |
| Components | 可复用 UI 组件 |
| Utils | 工具函数，常量定义 |

---

## 5. 核心功能实现方案

### 5.1 Skill 扫描模块

```swift
// Services/SkillScanner.swift
class SkillScanner {
    /// 扫描指定目录，返回所有 skill
    func scanDirectory(_ path: String) async throws -> [Skill]

    /// 解析 SKILL.md 文件
    private func parseSkillMetadata(at path: String) -> SkillMetadata?
}

// 扫描逻辑：
// 1. 遍历目录下的所有子目录
// 2. 检查子目录是否包含 SKILL.md
// 3. 解析 SKILL.md 的 frontmatter 获取 description
// 4. 构建 Skill 对象
```

### 5.2 配置管理模块

```swift
// Services/ConfigManager.swift
class ConfigManager: ObservableObject {
    @Published var sources: [Source]
    @Published var projects: [Project]
    @Published var globalSkills: [String: Bool]

    /// 保存配置到 UserDefaults
    func save()

    /// 加载配置
    func load()

    /// 读取项目配置文件
    func loadProjectConfig(at path: String) -> ProjectConfig

    /// 保存项目配置文件
    func saveProjectConfig(_ config: ProjectConfig, to path: String)
}
```

### 5.3 文件操作服务

```swift
// Services/FileService.swift
class FileService {
    /// 检查目录是否存在
    func directoryExists(_ path: String) -> Bool

    /// 打开 Finder 到指定目录
    func revealInFinder(_ path: String)

    /// 读取文件内容
    func readFile(_ path: String) throws -> String

    /// 写入文件
    func writeFile(_ path: String, content: String) throws
}
```

---

## 6. 开发迭代计划

### Phase 1: 基础框架（MVP）

**目标**: 完成项目初始化，实现基本的数据模型和 UI 框架

| 任务 | 优先级 | 预计工作量 |
|------|--------|-----------|
| 项目初始化（XcodeGen） | P0 | 小 |
| 数据模型定义 | P0 | 小 |
| 主视图框架 | P0 | 中 |
| Skill 扫描服务 | P0 | 中 |
| 来源目录管理 | P0 | 中 |

**验收标准**:
- 应用可以启动并显示基本 UI
- 可以添加/移除来源目录
- 可以扫描并显示 skill 列表

### Phase 2: 技能管理

**目标**: 实现完整的 skill 管理功能

| 任务 | 优先级 | 预计工作量 |
|------|--------|-----------|
| skill 启用/禁用 | P0 | 小 |
| skill 详情查看 | P0 | 小 |
| 搜索/筛选功能 | P1 | 中 |
| 一键同步 | P1 | 中 |

**验收标准**:
- 可以启用/禁用 skill
- 可以查看 skill 详情
- 可以搜索和筛选 skill
- 可以一键同步更新

### Phase 3: 项目管理

**目标**: 实现项目级别的 skill 配置

| 任务 | 优先级 | 预计工作量 |
|------|--------|-----------|
| 添加项目 | P0 | 小 |
| 切换项目 | P0 | 小 |
| 项目 skill 配置 | P0 | 中 |
| 项目收藏 | P1 | 小 |

**验收标准**:
- 可以添加项目
- 可以切换项目并查看配置
- 可以为项目配置 skill
- 可以收藏常用项目

### Phase 4: 优化完善

**目标**: 优化用户体验，处理边界情况

| 任务 | 优先级 | 预计工作量 |
|------|--------|-----------|
| 错误处理与提示 | P1 | 中 |
| 重复 skill 处理 | P1 | 中 |
| 空态设计 | P2 | 小 |
| 性能优化 | P2 | 中 |

---

## 7. 关键技术决策

### 7.1 为什么选择 MVVM

- SwiftUI 天然支持 ObservableObject
- 视图与业务逻辑分离，便于测试
- 状态管理清晰，数据流单向

### 7.2 为什么不用 CoreData

- 数据量小（最多 10 个来源目录，几十个 skill）
- CoreData 引入复杂度，收益不大
- UserDefaults + JSON 足够满足需求

### 7.3 异步处理方案

使用 Swift 5.5 的 async/await 处理文件系统操作：

```swift
Task {
    let skills = try await skillScanner.scanDirectory(path)
    await MainActor.run {
        self.skills = skills
    }
}
```

---

## 8. 边界情况处理

### 8.1 来源目录异常

| 情况 | 处理方式 |
|------|----------|
| 目录不存在 | 提示用户，从配置移除 |
| 目录无访问权限 | 提示用户，跳过该目录 |
| 目录为空 | 正常显示空列表 |

### 8.2 Skill 异常

| 情况 | 处理方式 |
|------|----------|
| SKILL.md 不存在 | 跳过该目录 |
| description 为空 | 显示"暂无描述" |
| 同名 skill | 弹窗让用户选择处理方式 |

### 8.3 项目异常

| 情况 | 处理方式 |
|------|----------|
| 项目目录不存在 | 提示用户，从列表移除 |
| 配置文件损坏 | 重新创建默认配置 |

---

## 9. 测试策略

### 9.1 单元测试

- 数据模型编解码测试
- Skill 扫描逻辑测试
- 配置读写测试

### 9.2 集成测试

- 完整的用户流程测试
- 边界情况测试

### 9.3 手动测试

- UI 交互测试
- 性能测试（100+ skill）

---

## 10. 文件清单

实现本方案需要创建的文件：

### 创建文件

```
SkillDock/
├── App/SkillDockApp.swift
├── App/ContentView.swift
├── Models/Skill.swift
├── Models/Source.swift
├── Models/Project.swift
├── Models/AppConfig.swift
├── ViewModels/SkillsViewModel.swift
├── ViewModels/ProjectsViewModel.swift
├── ViewModels/MainViewModel.swift
├── Services/SkillScanner.swift
├── Services/ConfigManager.swift
├── Services/FileService.swift
├── Services/SkillMetadataParser.swift
├── Views/Sidebar/SidebarView.swift
├── Views/Sidebar/SourcesSectionView.swift
├── Views/Sidebar/FavoriteProjectsView.swift
├── Views/Sidebar/AllProjectsView.swift
├── Views/Content/SkillsListView.swift
├── Views/Content/SkillRowView.swift
├── Views/Content/SearchBarView.swift
├── Views/Detail/SkillDetailView.swift
├── Components/ToastView.swift
├── Components/ConfirmDialog.swift
├── Utils/PathUtils.swift
├── Utils/Constants.swift
└── project.yml                 # XcodeGen 配置
```

---

*文档创建日期: 2025-02-27*
*版本: V1.0*