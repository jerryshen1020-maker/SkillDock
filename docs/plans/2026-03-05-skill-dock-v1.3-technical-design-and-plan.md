# SkillDock v1.3 技术方案与迭代计划

## 1. 背景与目标

v1.2 已完成多应用与 Git 来源能力，但在真实使用中暴露了 4 个关键问题：
- 技能列表展示语义偏差：当前列表来自“来源扫描结果”，不是“当前应用已安装结果”。
- 技能开关语义偏差：Toggle 与“是否安装”语义不一致，用户认为关闭应等价于移除。
- Git 操作阻塞交互：clone/pull 执行期间 UI 卡顿，影响连续操作体验。
- 交互细节不一致：侧栏 hover 切应用误触发、切换反馈不稳定、设置项冗余。

v1.3 目标：
- 列表语义切换为“已安装视角”。
- 操作语义切换为“移除 / 清空全部”。
- Git 全链路后台异步，不阻塞主交互。
- 应用切换改为 click 驱动并保持明确反馈。
- 移除主题配置相关功能，收敛设置页职责。

## 2. 范围定义

### 2.1 In Scope
- 技能列表数据源改为当前应用目标目录（`selectedAppSkillsPath`）实际内容。
- 顶部操作改为“一键同步 + 清空全部”，卡片操作改为“移除”。
- Git 来源新增、单仓更新、批量更新全部改为后台异步执行。
- 侧边栏应用切换由 hover 改为 click。
- 设置页移除主题模式，仅保留目录与同步相关操作。
- 来源目录数量限制移除（取消最多 10 个限制）。

### 2.2 Out of Scope
- 不引入新的项目维度配置模型。
- 不新增第三方依赖。
- 不调整 v1.2 已落地的冲突策略模型（保留/替换/批量）。

## 3. 用户流程（v1.3）

1) 用户点击左侧应用  
2) 右侧展示该应用“已安装技能列表”  
3) 用户可点击“一键同步”从来源安装到目标目录  
4) 用户可点击卡片“移除”删除单个安装项  
5) 用户可点击“清空全部”清理目标目录所有技能（含历史遗留）  
6) Git 来源在后台更新，页面可继续操作并看到进度反馈

## 4. 现状差距与改造点

### 4.1 数据层差距
- 现状：`filteredSkills` 基于 `skills`（来源扫描集合）过滤。
- 目标：`filteredSkills` 基于“目标目录已安装项”过滤。

改造要点：
- 新增已安装索引读取逻辑（建议 `InstalledSkillScanner`）。
- 将来源扫描结果与已安装结果解耦，分别服务“同步输入”和“界面展示”。

### 4.2 操作层差距
- 现状：卡片使用 Toggle 变更 `skillStates`。
- 目标：卡片提供“移除”，顶部提供“清空全部”，并有二次确认。

改造要点：
- 下线 `setSkillEnabled` 在 UI 的主路径。
- 新增 `removeInstalledSkill(folderName:)` 与 `clearAllInstalledSkills()`。
- 操作后统一刷新已安装列表并反馈消息。

### 4.3 Git 执行链路差距
- 现状：同步 `Process.waitUntilExit()`，阻塞调用链。
- 目标：异步任务执行，进度可见，失败可重试，不阻塞页面。

改造要点：
- `GitService` 提供 async API（clone/pull）。
- `MainViewModel` 增加 Git 任务状态字典（idle/running/success/failed + message）。
- 批量更新采用串行异步队列，单仓失败不终止整体。

### 4.4 交互差距
- 现状：hover 会触发应用切换。
- 目标：只允许 click 切换，切换有明确过渡动画。

改造要点：
- 移除 sidebar hover 切换逻辑。
- 保留轻量 transition，避免过重 spring 造成延迟感。

## 5. 模块级实现方案

### 5.1 MainViewModel
- 新增状态：
  - `installedSkills: [InstalledSkill]`
  - `isSyncing: Bool`
  - `gitOperationStates: [UUID: GitOperationState]`
- 新增方法：
  - `refreshInstalledSkills()`
  - `removeInstalledSkill(_:)`
  - `clearAllInstalledSkills()`
  - `syncSkillsToSelectedAppDirectory()` 完成后刷新 installed
  - `updateAllGitSourcesAsync()`
- 修改方法：
  - `selectApp(_:)` 切换后优先刷新 installed 列表
  - `addSource` / `addGitSource` 移除数量上限判断

### 5.2 GitService
- 接口升级：
  - `clone(...) async -> Result<Void, Error>`
  - `pull(...) async -> Result<Void, Error>`
- 可选扩展：
  - `onOutput: (String) -> Void` 输出回调
- 行为要求：
  - 保持错误文案可读
  - 不在主线程阻塞等待

### 5.3 视图层
- `SkillsRepositoryView`
  - 顶部按钮：`一键同步` + `清空全部`
  - 空态规则：空态不显示 `清空全部`
  - 同步中：按钮禁用 + 文案反馈
- `SkillCardView`
  - 移除 Toggle
  - 增加 `移除` 按钮
- `SidebarView`
  - 删除 hover 切换逻辑
- `SettingsView`
  - 移除主题模式卡片，保留目录与同步信息

## 6. 数据与兼容策略

- 保留 `AppConfig.legacySkillStates` 作为兼容字段，v1.3 UI 不再依赖该开关语义。
- 同步策略继续采用符号链接优先，失败记录到 diagnostics。
- 清空全部仅作用于当前应用目标目录，不影响来源目录。

## 7. 验收标准（核心）

- 切换应用后，列表仅显示该应用目标目录下已安装技能。
- 点击移除后，目标目录对应技能项被删除，列表即时刷新。
- 点击清空全部后，目标目录下技能项全部删除。
- Git clone/pull 过程不阻塞界面其他操作。
- 侧边栏仅点击切换应用，不再 hover 自动切换。
- 来源目录可超过 10 个且新增流程正常。

## 8. 测试计划

### 8.1 单元测试
- `MainViewModelSourcesTests`
  - 新增：移除单个安装项、清空全部、来源上限移除回归
  - 调整：列表断言从 source-scan 迁移为 installed-scan
- `SyncFlowTests`
  - 校验同步后 installed 列表刷新与空态切换

### 8.2 交互/UI 测试
- 应用 click 切换验证
- 空状态/同步中状态/清空确认弹窗/移除确认弹窗验证
- Git 后台更新时页面可继续操作验证

### 8.3 回归命令
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`

## 9. 迭代拆分

### Sprint A：语义切换（必须）
- 已安装列表接管展示链路
- 卡片移除 Toggle，改为移除动作
- 清空全部能力与确认弹窗

### Sprint B：Git 异步化（必须）
- GitService async 化
- MainViewModel 任务状态与批量更新链路
- 来源管理页进度反馈

### Sprint C：交互收口（必须）
- 侧边栏 click 切换
- 动画调优
- 设置页主题功能下线

### Sprint D：回归与发布检查（必须）
- 单测/UI 测试补齐
- 全量 build/test
- 视觉基线更新（如 UI 有差异）

## 10. 风险与应对

- 风险：已安装扫描与来源扫描并存，易产生状态不一致。
  - 应对：强制以“同步后立即 refreshInstalledSkills”作为唯一刷新出口。
- 风险：Git 异步输出过多导致主线程刷新频繁。
  - 应对：进度更新节流，状态聚合后再刷新 UI。
- 风险：历史主题与开关配置残留导致用户认知偏差。
  - 应对：首次进入 v1.3 给出一次性提示文案，说明交互语义升级为移除/清空。

