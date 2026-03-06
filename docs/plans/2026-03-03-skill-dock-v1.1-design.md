# SkillDock V1.1 设计文档

日期：2026-03-03
状态：设计完成，待实现

## 1. 目标与范围

本轮目标：在 V1.0 基础上交付 UX 优化与功能完善，包含 UI 改版、目录选择器、递归扫描、默认全局目录、Skill 开关生效。

不包含：skill 内容编辑、skill 导入导出、Trae/Trae CN 自动注入、逐条冲突处理。

## 2. 总体方案

### 2.1 架构延续

延续 V1.0 的 MVVM 架构，新增 UI 组件和服务能力：

```
Views (新增/重构)
├── Sidebar/          # 入口式侧边栏
│   ├── SidebarView.swift
│   └── SidebarEntryView.swift
├── Content/          # 内容区视图
│   ├── SkillsRepositoryView.swift    # Skills 仓库页
│   ├── ProjectsView.swift            # 项目列表页
│   └── SettingsView.swift            # 设置页
└── Components/      # 通用组件
    ├── SkillCardView.swift           # 技能卡片
    ├── SourceFilterView.swift        # 来源筛选器
    ├── ToastView.swift               # Toast 提示
    └── DirectoryPicker.swift         # 目录选择器

ViewModels (扩展)
└── MainViewModel.swift
    ├── 新增: selectedTab (侧边栏入口选择)
    ├── 新增: toastMessages (Toast 队列)
    └── 修改: 目录选择器集成

Services (新增)
├── DirectoryPickerService.swift      # NSOpenPanel 封装
├── ClaudeSettingsService.swift       # .claude/settings.json 读写
└── ToastService.swift                # Toast 状态管理

Models (扩展)
├── Source.swift
│   └── 新增: isBuiltIn (内置来源标识)
└── ToastMessage.swift                # Toast 消息模型
```

### 2.2 交付策略

采用纵向切片，每个切片可独立运行与验收：

1. **切片 A：UI 改版** - 入口式侧边栏 + 现代配色 + 网格卡片
2. **切片 B：目录选择器** - NSOpenPanel 集成
3. **切片 C：递归扫描** - 子目录遍历
4. **切片 D：默认全局目录** - 自动导入
5. **切片 E：Skill 开关生效** - .claude/settings.json 同步

## 3. 数据设计

### 3.1 模型扩展

**Source 扩展：**
```swift
struct Source {
    let id: UUID
    var path: String
    var displayName: String
    var addedAt: Date
    var isBuiltIn: Bool  // 新增：标识内置来源
}
```

**ToastMessage 新增：**
```swift
struct ToastMessage: Identifiable {
    let id: UUID
    let message: String
    let type: ToastType  // success, warning, error
    let duration: TimeInterval

    enum ToastType {
        case success    // 2s
        case warning    // 3s
        case error      // 5s
    }
}
```

**SidebarTab 新增：**
```swift
enum SidebarTab: String, CaseIterable {
    case skillsRepository = "Skills 仓库"
    case favoriteProjects = "常用项目"
    case allProjects = "全部项目"
    case settings = "设置"
}
```

### 3.2 Claude 配置结构

**项目级 .claude/settings.json：**
```json
{
  "permissions": {
    "allow": ["Skill(brainstorming)", "Skill(design-exploration)"],
    "deny": ["Skill(browser-use)"]
  }
}
```

**读取/写入服务：**
```swift
struct ClaudePermissions {
    var allow: Set<String>
    var deny: Set<String>
}

class ClaudeSettingsService {
    func readPermissions(projectPath: String) -> ClaudePermissions?
    func writePermissions(_ permissions: ClaudePermissions, projectPath: String) -> Bool
    func ensureClaudeDirectory(at projectPath: String) -> Bool
}
```

### 3.3 兼容策略

- 读取 `.claude/settings.json` 时处理不存在情况
- 写入时保留现有非 permissions 字段
- 配置损坏时静默失败，记录错误但不阻塞 UI

## 4. 核心流程

### 4.1 启动流程（新增默认目录）

1. 加载 AppConfig
2. 检测是否存在 `~/.claude/skills/`
3. 若存在且未添加过，自动添加为内置来源
4. 继续原有扫描流程

### 4.2 添加来源（目录选择器）

1. 用户点击"添加来源"
2. 弹出 NSOpenPanel（目录选择）
3. 用户选择目录后：
   - 路径校验 + 去重 + 上限校验
   - 预扫描目录（递归）
   - 同名冲突检测
   - 用户选择冲突策略
4. 写配置并刷新列表

### 4.3 递归扫描流程

1. 从来源目录开始
2. 使用 FileManager.enumerator 遍历所有子目录
3. 检测每个子目录是否包含 SKILL.md
4. 解析元数据并聚合
5. 按 sourcePath + folderName 生成稳定 ID

### 4.4 Skill 开关同步流程

1. 用户切换 Toggle
2. 更新本地 .skills-config.json
3. **新增**：同步更新 .claude/settings.json
   - 读取现有 permissions
   - 更新 allow/deny 列表
   - 写回文件
4. **新增**：Toast 反馈

### 4.5 项目切换流程（修订）

1. 落盘当前项目配置（.skills-config.json）
2. **新增**：落盘当前项目 Claude 配置（.claude/settings.json）
3. 读取目标项目配置
4. 刷新启用状态

## 5. 错误处理

### 5.1 目录选择器错误

| 场景 | 处理 |
|------|------|
| 用户取消 | 无操作 |
| 选择的路径无效 | Toast 警告 |
| 目录已存在 | Toast 警告 |

### 5.2 递归扫描错误

| 场景 | 处理 |
|------|------|
| 权限不足 | 跳过该子目录，记录错误 |
| 符号链接循环 | 检测并跳过 |
| 扫描超时 | 返回已扫描部分，提示用户 |

### 5.3 Claude 配置错误

| 场景 | 处理 |
|------|------|
| .claude 目录不存在 | 自动创建 |
| settings.json 损坏 | 备份旧文件，创建新文件 |
| 写入失败 | Toast 错误，本地配置仍然生效 |

## 6. 测试策略

### 6.1 单元测试

| 测试类 | 覆盖内容 |
|--------|----------|
| DirectoryPickerServiceTests | NSOpenPanel 调用、路径验证 |
| ClaudeSettingsServiceTests | permissions 读写、目录创建 |
| SkillScannerRecursiveTests | 递归扫描、符号链接、权限错误 |

### 6.2 集成测试

| 测试类 | 覆盖内容 |
|--------|----------|
| UITransformationTests | UI 改版后交互流程 |
| DefaultSourceTests | 默认全局目录添加 |
| SkillToggleSyncTests | Toggle 同步到 Claude 配置 |

### 6.3 手动验收

- 按设计稿验证 UI 还原度
- 验证 Toast 展示规则
- 验证目录选择器交互
- 验证递归扫描效果
- 验证 Claude 配置同步

## 7. 实施顺序

- **Step 1**：完成切片 A（UI 改版）
- **Step 2**：完成切片 B（目录选择器）
- **Step 3**：完成切片 C（递归扫描）
- **Step 4**：完成切片 D（默认全局目录）
- **Step 5**：完成切片 E（Skill 开关生效）
- **Step 6**：补齐测试和边界处理

## 8. 交付标准

- macOS 12+ 可运行
- UI 还原设计稿 ≥ 90%
- 启动 < 2s（典型数据规模）
- 递归扫描 100+ skills < 5s（目标）
- Toast 反馈符合规范
- Claude 配置写入成功 ≥ 95%（正常环境）
