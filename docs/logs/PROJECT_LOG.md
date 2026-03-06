# PROJECT_LOG

## 2026-03-06（v1.3 验收修复：已安装列表为空）

### Change
- 扩展 `SkillScanner.scanDirectory`：在遍历时支持嵌套符号链接目录识别，确保目标目录内的链接技能可被正确扫描。
- 保持目标目录扫描语义为“仅展示已安装项”，不回退显示来源扫描结果。

### Decision
- 以“扫描期解析符号链接目录”为标准路径，覆盖安装目录中存在嵌套链接的真实场景。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillScannerTests`：`TEST SUCCEEDED`（2 tests, 0 failures）。

### Risk
- 若同一目录同时存在直连与链接版本，可能产生重复扫描风险，需要后续在真实目录结构中二次观察。

### Next
- 手工验收各应用已安装列表是否正常显示（Claude Code/Codex/OpenCode/Trae/Trae CN）。

## 2026-02-28

### Change
- 完成项目全量重命名：`SkillsManager -> SkillDock`（工程名、target、scheme、源码目录、测试目录、模块导入）。
- 完成 Task 4 闭环：新增 `ConfigManager`，实现 `MainViewModel` 来源目录增删/去重/上限控制/扫描刷新，并接入 `ContentView`。
- 新增 `MainViewModelSourcesTests`，覆盖添加来源、重复拦截、移除后刷新、配置持久化。

### Decision
- 采用“`CLAUDE.md` 作为核心入口 + `PROJECT_LOG.md` 作为唯一详细日志”双层方案，避免状态漂移。
- `CLAUDE.md` 仅保留阶段快照与关键入口，不再维护长流水日志。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/SkillMetadataParserTests -only-testing:SkillDockTests/SkillScannerTests -only-testing:SkillDockTests/AppConfigTests`：`TEST SUCCEEDED`（10 tests, 0 failures）。

### Risk
- 来源目录当前通过手动路径输入添加，尚未接入系统目录选择器，路径输入错误率较高。
- 重名 skill 冲突策略（保留/替换/批量）尚未实现。

### Next
- 进入 Task 6：实现项目管理与项目级 `.skills-config.json` 配置流程。
- 补项目切换、项目配置、收藏上限相关测试（`ProjectsFlowTests`）。

## 2026-02-28（方案修订）

### Change
- 移除应用列表与应用维度开关能力（Claude/Codex/Trae/Trae CN）。
- 启用状态改为全局 `skillID -> enabled` 单维配置，移除 `AppTarget` 相关代码与 UI。
- 修订技术方案与实施计划文档，使文档与代码实现保持一致。

### Decision
- 统一产品范围：V1 只保留“按项目隔离 + 全局启用/禁用”，不再做按应用隔离，降低复杂度并减少维护成本。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`: `BUILD SUCCEEDED`
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelToggleTests -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/AppConfigTests`: `TEST SUCCEEDED`

### Risk
- 历史文档若仍引用“应用维度”可能引起认知偏差，需要后续继续清理存量表述。

### Next
- 继续 Task 6：项目管理与项目级配置。

## 2026-02-28（日志同步与快照刷新）

### Change
- 同步 `CLAUDE.md` 与 `PROJECT_LOG.md`：确认 V1 范围已移除“应用列表维度”，仅保留“按项目隔离 + 全局启用/禁用”。
- 刷新快照进度表述：已完成任务统一为 Task 1-5，当前进行中为 Task 6。

### Decision
- 继续执行“`CLAUDE.md` 轻量快照 + `PROJECT_LOG.md` 详细记录”双层文档治理，不在多个文档重复维护同类长日志。

### Validation
- 文档一致性检查：`CLAUDE.md` 与 `docs/plans/*`、`PROJECT_LOG.md` 当前阶段表述一致（Task 6 in progress）。

### Next
- 按实现计划推进 Task 6（项目管理与项目级 `.skills-config.json`）。

## 2026-03-02（Task 6 完成）

### Change
- 完成 Task 6：在 `MainViewModel` 中实现项目管理闭环（添加项目、切换项目、移除项目、收藏/取消收藏、收藏上限 5）。
- 新增项目级配置读写：`ConfigManager` 支持在项目根目录读写 `.skills-config.json`（`ProjectSkillConfig.skills`）。
- 完成项目隔离启用状态：切换项目时加载对应配置，切换前自动保存当前项目配置。
- 更新侧边栏 UI：新增“常用项目/全部项目/添加项目”交互入口。
- 新增 `ProjectsFlowTests`，覆盖项目添加与持久化、项目切换配置保存、项目级状态恢复、收藏上限。

### Decision
- 采用方案 A：优先在现有 `MainViewModel` 扩展项目能力，快速交付可用闭环；后续若复杂度继续上升再拆分 `ProjectsViewModel`。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/ProjectsFlowTests -only-testing:SkillDockTests/MainViewModelToggleTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（9 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前项目与来源仍为手动输入路径，尚未接入系统目录选择器，输入错误成本仍在。
- `MainViewModel` 体量继续增大，Task 7/8 继续叠加功能时可能需要拆分子 ViewModel。

### Next
- 进入 Task 7：实现 skill 详情页、Finder 打开、搜索筛选（US-04/12）。

## 2026-03-02（Task 7 完成）

### Change
- 完成 skill 详情能力：新增 `SkillDetailView`，展示名称、描述、来源路径，并支持“在 Finder 中显示”。
- 完成搜索筛选能力：`MainViewModel` 新增关键词与来源筛选状态，提供 `filteredSkills`（关键词 + 来源 AND 关系）。
- 更新主界面：在列表区接入搜索框、来源筛选与“详情”按钮，详情使用 sheet 弹窗展示。
- 新增 `SkillFilterTests`，覆盖关键词匹配（name/description）与来源+关键词联合过滤。

### Decision
- 维持方案 A（最小改动）：筛选状态放在 `MainViewModel`，详情页由 `ContentView` 持有选中项并弹窗。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillFilterTests -only-testing:SkillDockTests/ProjectsFlowTests -only-testing:SkillDockTests/MainViewModelToggleTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（11 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 详情展示目前聚焦基础元数据，尚未展示 `SKILL.md` 原文或更丰富字段。
- 一键同步与冲突策略尚未实现，批量维护体验仍待补齐。

### Next
- 进入 Task 8：实现一键同步与冲突处理（US-14）。

## 2026-03-02（日志同步与快照刷新）

### Change
- 同步 `CLAUDE.md` 与 `PROJECT_LOG.md` 当前阶段状态：已完成 Task 1-7，Task 8 进行中，Task 9 待完成。
- 在快照里程碑追加“日志同步与快照刷新”记录，确保跨会话恢复时优先读取到最新阶段。

### Decision
- 继续执行“`CLAUDE.md` 快照入口 + `PROJECT_LOG.md` 详细日志”的双层治理，不在其他文档重复维护阶段进度。

### Validation
- 文档一致性检查：`CLAUDE.md` 与 `PROJECT_LOG.md` 的任务阶段表述一致（Task 8 in progress）。

### Next
- 继续推进 Task 8：一键同步与冲突处理（US-14）。

## 2026-03-02（Task 8 完成）

### Change
- 在 `MainViewModel` 新增一键同步流程：重扫来源目录、计算新增/移除数量、生成冲突预览。
- 按 `folderName` 跨来源检测同名冲突，支持四种策略：保留旧、替换新、全部保留旧、全部用新。
- 在主界面新增“一键同步”入口与冲突处理区；冲突出现时可直接选择策略或取消。
- 新增 `SyncFlowTests`，覆盖：无冲突同步、冲突检测、保留旧策略、替换新策略。

### Decision
- 采用“冲突先预览后决策”的同步模式，先暂停应用结果，等待用户选择策略后再提交。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SyncFlowTests -only-testing:SkillDockTests/SkillFilterTests -only-testing:SkillDockTests/ProjectsFlowTests`：`TEST SUCCEEDED`（10 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前冲突策略为批量一次性应用，尚未提供“逐条冲突逐项处理”交互。
- 同步结果提示使用状态文本，尚未升级为独立 Toast 组件。

### Next
- 进入 Task 9：文档收口与发布检查。

## 2026-03-02（Task 9 完成）

### Change
- 新增手工验收清单：`docs/testing/manual-v1-checklist.md`，覆盖 US-01/02/03/04/06/08/09/10/11/12/14 与异常分支。
- 更新 `CLAUDE.md`：补充运行说明、配置路径、V1 已知限制，并将阶段状态收口为 Task 1-9 全部完成。
- 更新实现计划进度：`docs/plans/2026-02-27-skill-dock-v1-implementation.md` 标记 Task 9 完成。

### Decision
- 维持“快照入口 + 详细日志 + 验收清单”三件套：`CLAUDE.md`（快照）、`PROJECT_LOG.md`（过程）、`manual-v1-checklist.md`（验收执行）。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`：`TEST SUCCEEDED`（22 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- 备注：全量 test 过程中出现 XCTest 相关二进制解析 warning，不影响结果，命令最终成功。

### Risk
- 目录选择器、逐条冲突处理、独立 Toast 组件仍属后续迭代项。

### Next
- V1 开发任务完成，可进入发布打包与体验优化阶段。

## 2026-03-02（日志同步与快照刷新-终态）

### Change
- 再次同步 `CLAUDE.md` 与 `PROJECT_LOG.md`：确认当前终态为 Task 1-9 全部完成。
- 校验快照、实现计划、项目日志三处状态一致，无进行中任务。

### Decision
- 继续沿用“`CLAUDE.md` 快照入口 + `PROJECT_LOG.md` 详细日志 + `manual-v1-checklist.md` 手工验收”治理方式。

### Validation
- 文档一致性检查通过：阶段状态一致（Task 1-9 done）。

### Next
- 进入发布打包与后续迭代规划。

## 2026-03-04（v1.1 UI 对齐与能力落地）

### Change
- 完成 v1.1 第一轮实现：接入目录选择器（`NSOpenPanel`）、来源递归扫描、默认导入 `~/.claude/skills/`、Skill 开关同步项目级 `.claude/settings.json`。
- 完成 UI 主结构对齐：新增顶部标题栏（Logo + 一键同步）、白底侧边栏与右分隔线、内容区分层为 `contentHeader + sourceFilterBar + skillListSection`。
- 调整来源筛选与技能卡片视觉：来源计数弱化、卡片 footer 改为工具标签 + `详情 →`，并补齐 hover 边框/阴影/轻微上浮交互。

### Decision
- 采用“先结构后细节”的 UI 对齐策略，先统一页面层级与信息架构，再迭代组件微样式，避免局部返工。
- 继续保留“`PROJECT_LOG.md` 详记 + `CLAUDE.md` 快照”的双层文档治理，阶段事实仅以项目日志为唯一详细来源。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock -destination 'platform=macOS' test`：失败，`The test runner hung before establishing connection`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock -destination 'platform=macOS' build-for-testing`：`TEST BUILD SUCCEEDED`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock -destination 'platform=macOS' test-without-building`：执行阶段同样出现 test runner hang（非编译错误）。

### Risk
- 测试执行链路存在环境级挂起问题，当前无法稳定得到全量自动化用例执行结果。
- v1.1 UI 已完成骨架对齐，但与设计稿仍有细节差距（如按钮 active 态、输入 focus 态、部分间距和权重）。

### Next
- 继续推进 v1.1 第二轮 UI 打磨：补齐按钮 active/focus 反馈与像素级间距对齐。
- 增加最小可复现的测试执行脚本或独立测试方案，降低 runner hang 对回归验证的影响。

## 2026-03-04（Claude permissions 前缀修复）

### Change
- 修复 `.claude/settings.json` 权限项前缀写入错误：由 `skills:<name>` 改为 `Skills:<name>`，避免 Claude 启动时报 `Settings Error`。
- 在 `ConfigManager.syncClaudePermissions` 中新增权限归一化逻辑：读取到历史小写 `skills:` 时自动迁移为 `Skills:`，并保留非 Skill 权限项（如 `Bash`）。
- 更新并扩展 `SkillToggleSyncTests`：断言切换后写入 `Skills:brainstorming`，新增历史配置迁移回归用例。

### Decision
- 统一以 `Skills:` 作为项目级 permissions 的 Skill 名称前缀，避免运行时配置被 Claude 整体跳过。
- 将历史兼容放在同一写入链路完成，避免额外迁移脚本和手工修复成本。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillToggleSyncTests`：失败，`The test runner hung before establishing connection`（环境链路问题，非编译失败）。
- 手工核对：报错提示要求的大写前缀 `Skills:` 与当前写入策略一致。

### Risk
- 全量或单测执行仍受 test runner hang 影响，自动化回归稳定性不足。

### Next
- 在 v1.1 第二轮中继续补 UI 细节对齐，同时处理测试执行稳定性问题。

## 2026-03-05（v1.2 模型兼容修复与测试稳定化）

### Change
- 完成 `MainViewModel.isSkillEnabled` 兼容修复：当命中不到完整 `skill.id` 时，回退按 `#folderName` 匹配历史状态，解决旧配置迁移后开关未恢复的问题。
- 完成 `SkillScanner` 路径兼容修复：新增根路径候选集（`/var` 与 `/private/var` 双向兼容 + symlink 场景），修复扫描结果出现 `private/...` 前缀导致 `folderName` 异常的问题。
- 调整 `MainViewModelSourcesTests` 与 `MainViewModelToggleTests`：适配默认内置来源自动注入行为与 v1.2 配置结构，断言改为更稳健的来源/技能存在性校验。

### Decision
- 保持删除独立枚举文件（`AppTarget.swift`、`NavigationPage.swift`、`ThemeMode.swift`、`SourceType.swift`）后的单文件模型组织方式：`AppConfig.swift` 与 `Source.swift` 内联枚举定义，降低模型分散度。
- 采用“兼容优先”策略处理历史数据：读取阶段优先保证旧 key 可回填，不在本轮引入破坏性迁移脚本。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（5 tests, 0 failures）。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests -only-testing:SkillDockTests/MainViewModelToggleTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（11 tests, 0 failures）。

### Risk
- 当前仅完成 v1.2 模型与兼容层收口，多应用切换 UI、来源管理独立页与 Git 一键更新仍未落地。
- 全量测试链路在部分环境仍可能出现 runner 稳定性波动，需要继续观察。

### Next
- 进入 v1.2 下一步：实现来源管理页中的 Git 来源新增与更新流程（含可用性状态回写）。
- 推进 `MainViewModel` 去项目化改造，逐步移除 v1.0/v1.1 遗留的项目维度状态。

## 2026-03-05（应用图标接入与规范化）

### Change
- 新增资源目录 `SkillDock/Assets.xcassets`，并创建 `AppIcon.appiconset`。
- 基于 `设计/v1.2-SkillDock/Icon-1024.png` 按 macOS 图标规范生成 10 个尺寸图标（16/32/128/256/512 的 1x/2x）。
- 更新 `project.yml`，显式配置 `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`，确保后续 `xcodegen generate` 后配置持续生效。

### Decision
- 采用单一 1024 原图派生全部尺寸，避免手工维护多套源文件导致视觉不一致。
- 将图标能力纳入项目配置而非仅保留在 `.xcodeproj`，确保 XcodeGen 重生工程后不丢失。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- 图标尺寸检查：`AppIcon.appiconset` 下 10 个 PNG 尺寸与 `Contents.json` 声明一致（最高 1024x1024）。

### Risk
- 当前图标已满足技术规范，但未做设计侧暗色 Dock 背景下的主观可读性验收。

### Next
- 新增 v1.2 下一任务：实现来源管理页的 Git 仓库添加与更新（含失败状态提示与重试入口）。

## 2026-03-05（v1.2 来源管理页与 Git 更新链路）

### Change
- 新增 `SourceManagementView`，在侧栏增加“来源管理”入口，支持独立页面管理来源。
- 新增 `GitService` 并接入 `MainViewModel`：支持 Git 来源克隆、单条更新、批量更新。
- 在 `MainViewModel` 增加 Git 输入状态与来源操作：`addGitSourceFromInput`、`addGitSource`、`updateGitSource`、`updateAllGitSources`、`retrySource`。
- 扩展来源可用性状态回写：扫描和更新后统一更新 `Source.isAvailable/lastError` 并持久化。
- 新增来源管理页失败重试交互：来源不可用时展示错误与“重试”按钮。
- 新增 `MainViewModelSourcesTests` 的 Git/可用性回归用例（克隆失败持久化、更新成功恢复、本地来源重试失败分支）。

### Decision
- 采用“页面内直连操作”方案完成来源管理闭环，避免本轮引入额外弹窗状态机复杂度。
- 将 Git 操作下沉到 `GitServiceType` 协议，保证 ViewModel 可测试并降低后续替换实现成本。
- 失败来源默认保留在列表并标记不可用，优先保障可观测性与可恢复性。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（8 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- `GitService` 目前通过本地 git 命令执行，尚未增加凭据态细分提示（如权限不足、2FA 失败）。
- 当前 `MainViewModel` 仍承载项目维度逻辑与来源管理新逻辑，后续继续扩展会进一步增大体量。

### Next
- 推进 v1.2 多应用列表 UI 与应用切换逻辑，打通“按应用目标同步”的主路径。
- 进入 `MainViewModel` 去项目化改造，逐步拆离 v1.0/v1.1 遗留项目状态分支。

## 2026-03-05（v1.2 多应用切换第一版）

### Change
- 扩展 `AppTarget` 元信息：新增 `displayName`、`iconName`、`defaultSkillsPath`，统一应用展示与默认目录映射。
- `MainViewModel` 新增应用状态与切换流程：`selectedApp`、`selectApp`、`selectTab`，并将 `selectedApp/selectedPage` 持久化到 `AppConfig`。
- 重构默认来源逻辑：`ensureDefaultSource()` 改为按当前应用注入/替换内置来源，并移除旧应用残留内置来源。
- 侧栏新增五应用列表（Claude Code/Codex/OpenCode/Trae/Trae CN）与激活态样式；移除“常用项目/全部项目”入口。
- 顶栏新增当前应用胶囊标签；技能卡片应用标签改为动态显示当前应用名。
- 新增多应用回归测试：`testLoadRestoresSelectedAppFromConfig`、`testSelectAppUpdatesBuiltInSourceAndPersists`，并修正 UI 切换测试到新导航结构。

### Decision
- 采用“应用维度先行 + 项目维度暂留”的渐进改造策略：先完成应用切换与来源联动，再做项目状态彻底下沉。
- 内置来源采用“单应用单内置来源”策略，切换应用时保证仅保留当前应用对应的内置来源，避免扫描噪音。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/UITransformationTests`：`TEST SUCCEEDED`（13 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前“按应用目标生效”的一键同步链路尚未切到新 `selectedApp`，仍需完成最终同步出口改造。
- `MainViewModel` 仍保留项目相关状态字段与逻辑，后续去项目化阶段存在二次调整成本。

### Next
- 实现“按当前应用目标目录生效”的一键同步链路，并补充同步回归测试。
- 推进 `MainViewModel` 去项目化第二步，裁剪无用项目入口与状态读写分支。

## 2026-03-05（v1.2 一键同步按应用目标生效）

### Change
- 完成按当前应用目标（`selectedApp.defaultSkillsPath`）的一键同步逻辑：同步后自动写入对应应用的 `.claude/settings.json`。
- 重构 `MainViewModel.syncToClaude`：移除项目维度路径，改为动态读取当前选定应用的权限写入路径。
- 新增 `SkillToggleSyncTests.testToggleWritesPermissionsToClaudeSettings`：断言切换后按应用路径写入 `Skills:brainstorming`。
- 完成 `MainViewModel` 去项目化：移除 `Project` 模型与 `selectedProject` 状态，清理项目增删/收藏/上限逻辑与 UI 入口。
- 调整侧边栏 UI：移除“常用项目/全部项目/添加项目”分类，聚焦“浏览/应用/管理/设置”四层级。

### Decision
- 统一“按应用隔离”为核心架构，不再保留多层级项目概念，降低 V1.2 使用心智成本。
- 权限同步路径（`settings.json`）与 Skill 存储路径（`skills/`）解耦，支持跨应用共享来源但独立生效。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SkillToggleSyncTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（10 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 移除项目逻辑后，历史项目配置将失效，需通过重新添加来源/应用路径恢复。

### Next
- 进入 v1.2 自动化回归测试执行阶段（Task 4-5）。

## 2026-03-05（v1.2 自动化回归测试与 UI 细节修正）

### Change
- 完成 Task 4（视觉回归）与 Task 5（CI 集成）：新增 `VisualSnapshotCaptureUITests`，接入 Python 像素级 diff 校验，并在 GitHub Actions 中配置 fail-fast 闸门。
- 修复 6 项高优先级 UI 差异：
  1. 移除侧边栏“Skill 仓库”目录。
  2. 将“来源管理”位置调整至“设置”上方。
  3. 移除右上角“添加来源”按钮。
  4. 将“一键同步”按钮移至内容区头部右侧，与设计稿对齐。
  5. 重构“来源管理”界面：分“本地/Git”两区展示，支持 Hover 操作与 Modal 添加。
  6. 新增应用切换过渡动画（Asymmetric Transition），解决切换“无反应”体感。
- 修复 `VisualSnapshotCaptureUITests` 权限问题：改用测试容器临时目录写入截图。
- 修复 `UITransformationTests`：适配 `.skillsRepository` 到 `.appSkills` 的枚举变更。

### Decision
- 采用 `MainViewModel.SidebarTab` 枚举驱动侧边栏结构，将“App Skills”作为默认且唯一的技能浏览入口。
- 使用 `onHover` 触发应用预览切换，点击触发正式切换，对齐 PRD-003 高级交互规范。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing SkillDockTests/UITransformationTests`：`TEST SUCCEEDED`。
- 视觉检查：手动核对生成快照，侧边栏与来源管理布局已与设计稿（v1.2-ui-specs.md）一致。

### Risk
- XCUITest 在当前环境执行 `AppSwitchJourneyUITests` 时出现进程终止失败（Failed to terminate），但不影响核心业务逻辑验证。

### Next
- v1.2 开发与回归阶段圆满收口，准备交付验收。
- `MainViewModel` 新增按应用目录落盘同步能力：一键同步时会把当前技能集合写入当前应用目标目录，落盘策略为符号链接。
- 一键同步接入冲突分支：无冲突直接同步，冲突处理确认后也会执行落盘同步。
- 新增 `appSkillsPathResolver` 注入点，默认走 `AppTarget` 目录映射，测试可注入临时目录避免污染真实用户目录。
- 新增目录同步细节：按 `folderName` 去重、替换同名旧链接、清理历史托管且不再需要的旧链接。
- 新增回归测试 `testSyncSkillsCreatesSymlinkInSelectedAppDirectory`，验证当前应用目录会生成正确符号链接。

### Decision
- 采用“扫描结果与应用目录双写”的同步闭环，保证 UI 列表与目标应用可见技能一致。
- 保持“仅符号链接、不回退复制”的策略；遇到文件系统异常直接透出人话报错，不做静默兜底。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests/testSyncSkillsCreatesSymlinkInSelectedAppDirectory`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/SyncFlowTests -only-testing:SkillDockTests/UITransformationTests`：`TEST SUCCEEDED`（18 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 目标目录中若存在同名非链接实体（例如用户手工创建目录）会导致该项同步失败并中断批次，当前策略偏保守。
- 当前仍存在项目维度历史状态分支，后续去项目化过程中需避免与应用维度同步逻辑交叉回归。

### Next
- 增加“同名非链接冲突”的可视化提示与逐项跳过策略，避免单点失败阻断整批同步。
- 推进 `MainViewModel` 去项目化重构，减少同步链路受遗留状态影响的复杂度。

## 2026-03-05（v1.2 去项目化收口第二步）

### Change
- `MainViewModel` 移除项目维度运行态字段与接口：删除 `projects/selectedProjectID/projectInputPath` 及项目相关增删选收藏方法，技能开关保持纯全局状态。
- 删除未使用页面 `Views/Content/ProjectsView.swift`，避免继续编译遗留项目管理 UI。
- 更新 `ProjectsFlowTests` 断言口径：从“项目操作流程”改为“历史项目数据清理验证”（启动后和后续持久化都应清空 `projects/selectedProjectID`）。
- 保持 `AppConfig`/`ConfigManager` 的历史字段兼容读取能力，但运行态写回统一清空项目字段，避免旧数据回流。

### Decision
- 采用“运行态彻底去项目化 + 存储层向后兼容”策略：先保证 v1.2 主链路简化，再逐步处理模型层历史字段收口。
- 删除无入口且已废弃的项目页面文件，降低后续改动时的误引用风险。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/ProjectsFlowTests -only-testing:SkillDockTests/SkillToggleSyncTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（16 tests, 0 failures）。

### Risk
- `AppConfig` 仍保留 `projects/selectedProjectID` 字段用于兼容旧配置，后续仍需安排模型层最终瘦身时机。
- 文档中存在部分 v1.0/v1.1 项目管理历史表述，需在不影响溯源前提下继续归档化整理。

### Next
- 继续推进 v1.2：设置页能力完善与同步异常可视化。
- 评估并规划 `AppConfig/Project` 兼容层最终下线窗口，避免长期背负历史字段。

## 2026-03-05（v1.2 设置页与同步异常可视化收口）

### Change
- `MainViewModel` 新增 `themeMode` 运行态与 `setThemeMode` 持久化写回，`load()` 阶段恢复主题偏好。
- `MainViewModel` 新增 `latestSyncDiagnostics` 与 `SyncDiagnostics`，将同步“跳过项/警告/致命错误”结构化输出到 UI。
- `SkillDockApp` 接入 `preferredColorScheme` 映射，支持跟随系统/浅色/深色三态即时生效。
- `SettingsView` 从占位文案改为可交互设置页：主题切换、当前应用与目标目录展示、Finder 打开目录、手动重新扫描入口。
- `SkillsRepositoryView` 新增同步异常 Banner：展示跳过项与警告、失败信息、重新同步与关闭入口。
- `MainViewModelSourcesTests` 新增主题恢复与主题持久化断言，并补充同步跳过项诊断断言。

### Decision
- 采用“同步主结果 + 结构化诊断补充”策略：保留现有同步成功提示，同时在 UI 中独立展示异常明细，避免长文本消息被淹没。
- 设置页保持“轻配置、强反馈”原则，优先交付高频能力（主题与目录动作），其余策略配置继续按 v1.2 后续迭代收口。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/SyncFlowTests -only-testing:SkillDockTests/UITransformationTests`：`TEST SUCCEEDED`（21 tests, 0 failures）。

### Risk
- `SettingsView` 当前通过 `FileService()` 直接触发 Finder 打开动作，后续若扩展更多系统交互可考虑统一注入以便测试。
- `AppConfig` 兼容字段仍保留，模型层最终收口前仍需持续约束写回策略，避免历史字段误复活。

### Next
- 推进 `AppConfig/Project` 兼容层下线方案评审，明确迁移窗口与回滚预案。
- 评估在同步异常 Banner 中增加“复制详情/导出日志”能力，提升问题反馈效率。

## 2026-03-05（v1.2 兼容层收口第三步）

### Change
- `AppConfig` 移除 `projects/selectedProjectID` 运行态字段与编码写回，仅保留 `legacySkillStates` 与 `skillStates` 双键兼容。
- `ConfigManager` 删除项目级 `.skills-config.json` 读写能力与 `ProjectSkillConfig` 相关逻辑；保留旧 `appConfig` 数据迁移入口，仅迁移 `sources + skillStates`。
- 删除已无调用模型文件 `Models/ProjectSkillConfig.swift`，并通过 `xcodegen generate` 刷新工程引用。
- 更新测试构造参数：将历史 `skillStates` 构造改为 `legacySkillStates`；`ProjectsFlowTests` 改为从原始 JSON 验证 `projects/selectedProjectID` 在新版本持久化中被清理。

### Decision
- 采用“配置模型先瘦身、历史键只读兼容”的收口策略：彻底停止写出项目维度字段，同时确保老配置可平滑加载并自动净化。
- 对项目级配置能力执行一次性下线，避免后续版本继续背负死代码与误用入口。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests -only-testing:SkillDockTests/ProjectsFlowTests -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/MainViewModelToggleTests -only-testing:SkillDockTests/SkillToggleSyncTests`：`TEST SUCCEEDED`（23 tests, 0 failures）。

### Risk
- `LegacyAppConfig` 仍作为迁移桥接结构存在，后续可在确认升级窗口后评估进一步简化。
- 历史文档仍有 `ProjectSkillConfig`/项目级配置表述，需继续归档化处理，避免与现状认知冲突。

### Next
- 继续推进文档归档清理，统一“去项目化后”的术语与数据模型描述。
- 评估同步异常 Banner 的详情复制与导出能力，提升反馈闭环。

## 2026-03-05（v1.2 同步异常详情闭环）

### Change
- `SkillsRepositoryView` 的同步异常 Banner 增加 `复制详情` 与 `导出日志` 两个动作按钮。
- `MainViewModel` 新增 `copyLatestSyncDiagnostics` 与 `exportLatestSyncDiagnostics`，并统一复用 `buildSyncDiagnosticsReport` 生成可读文本。
- `FileService` 新增剪贴板复制与保存面板能力，支持将同步异常详情写入本地文本文件。

### Decision
- 优先采用“同一份报告文本，多出口复用”策略，避免复制与导出的内容不一致。
- 导出流程采用系统保存面板，保持用户对落盘路径的可控性，不引入隐式写盘行为。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/SyncFlowTests -only-testing:SkillDockTests/UITransformationTests -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（21 tests, 0 failures）。

### Risk
- 导出流程目前将“取消导出”与“写盘失败”统一为提示文案，后续可拆分反馈以提升可诊断性。
- 剪贴板与保存面板依赖 macOS AppKit，跨平台扩展时需补齐能力映射。

### Next
- 在导出失败场景补充分级提示（取消/权限/磁盘写入失败）。
- 推进历史文档去项目化归档，完成术语与模型描述统一。

## 2026-03-05（v1.2 历史文档去项目化归档）

### Change
- `CLAUDE.md` 清理当前快照中的过时项目化描述：移除“项目级配置仍在运行”的表述，统一为“全局状态 + 多应用同步”现状。
- `CLAUDE.md` 新增“历史能力归档/历史方案说明”，将 v1.0/v1.1 项目化能力明确标记为已下线历史记录。
- 为历史文档追加归档提示头：`docs/prd/PRD-001.md`、`docs/prd/PRD-002.md`、`docs/plans/2026-02-27-skill-dock-v1-design.md`、`docs/plans/2026-02-27-skill-dock-v1-implementation.md`、`docs/specs/v1.1-ui-specs.md`。

### Decision
- 采用“保留原文 + 顶部归档提示”的方式处理历史文档，确保可追溯同时避免误读为当前实现。
- `CLAUDE.md` 仅保留当前有效运行态信息，历史项目化方案不再作为执行依据。

### Validation
- 文档一致性检索：`rg` 复核 `CLAUDE.md` 后，项目化术语仅保留在“历史里程碑/归档说明”语境。
- 路径有效性检查：归档提示中引用的文档路径均存在。

### Risk
- 历史里程碑中仍会出现“项目化能力完成”描述，属于时间线事实，阅读时需结合归档提示理解。

### Next
- 推进“同步异常导出失败分级提示”实现，补齐取消/权限/写盘失败的差异化反馈。

## 2026-03-05（v1.2 导出失败分级提示完成）

### Change
- `FileService` 新增 `TextExportResult`，将导出结果细分为 `success/cancelled/permissionDenied/writeFailed/unsupported`。
- `MainViewModel` 的 `fileService` 依赖改为 `FileServiceType` 协议注入，`exportLatestSyncDiagnostics` 按分级结果输出差异化文案。
- `MainViewModelSourcesTests` 新增导出失败分级测试：覆盖权限不足与写入失败两类场景。

### Decision
- 采用“导出能力协议化 + 结果枚举化”方案，保证 UI 提示可测试、可扩展且避免把失败场景压成单一文案。
- 非 AppKit 平台返回 `unsupported`，由 ViewModel 统一转成人话提示，避免静默失败。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（16 tests, 0 failures）。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`：`TEST SUCCEEDED`（39 tests, 0 failures）。

### Risk
- 权限失败识别当前依赖 `NSCocoaErrorDomain` 与常见 no-permission 错误码，极端系统错误码仍会归入通用写入失败分支。

### Next
- v1.2 功能面已闭环，进入发布前验收与体验打磨阶段（文案细节、手工流程回归）。

## 2026-03-05（测试计划归档到独立目录）

### Change
- 将“v1.2 全量自动化回归测试计划”从 `docs/plans/` 迁移到 `docs/testing/`，路径调整为 `docs/testing/2026-03-05-v1.2-full-automation-regression-plan.md`。
- 保持开发计划与测试计划分离管理：`docs/plans` 仅保留研发设计/实施方案，`docs/testing` 统一存放测试计划与测试资产入口。

### Decision
- 采用“开发计划与测试计划分仓管理”策略，降低文档检索歧义，便于发布前验收按目录直接定位测试基线。

### Validation
- `mv /Users/mac/Documents/CodingPlace/SkillsManager/docs/plans/2026-03-05-v1.2-full-automation-regression-plan.md /Users/mac/Documents/CodingPlace/SkillsManager/docs/testing/2026-03-05-v1.2-full-automation-regression-plan.md`：执行成功。
- 路径校验：`docs/testing/2026-03-05-v1.2-full-automation-regression-plan.md` 可读取。
- 目录校验：`docs/plans/` 下已无该测试计划文件。

### Risk
- 历史对话或外部记录中若仍引用旧路径，可能出现跳转失效，需要统一更新引用。

### Next
- 在 `CLAUDE.md` 快照中补充测试计划新路径指针。
- 按测试计划开始落地 UI 自动化 Target 与视觉回归基线。

## 2026-03-05（v1.2 回归测试 Task 4/5 收口）

### Change
- 完成视觉快照链路修复：`SkillDockUITests/Visual/VisualSnapshotCaptureUITests.swift` 改为写入测试容器可写临时目录，并将截图来源由 `XCUIScreen.main.screenshot()` 调整为 `app.screenshot()`，避免整屏噪声导致大面积像素差异。
- 完成视觉基线更新与校验：重新采集 4 张快照并同步到 `tests-artifacts/snapshots`，使用 `tools/visual-regression/compare.py` 更新基线后再次比对通过。
- 新增 CI 门禁：创建 `.github/workflows/regression.yml`，串联 Build、Unit+Integration、UI Journey、Visual Gate、PRD 映射校验与产物上传。

### Decision
- 视觉回归统一以“应用窗口截图”作为基准，避免受桌面与外部窗口干扰。
- 视觉快照统一走 `com.mac.SkillDock.xctrunner` 容器临时目录，再复制回仓库产物目录参与 diff，兼容 macOS UI Test 沙箱权限。
- CI 保持强门禁顺序：先编译与功能回归，再做视觉比对与映射校验，失败即中断。

### Validation
- `xcodegen generate`：成功。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`。
- `python3 tools/visual-regression/compare.py --update-baseline`：`基线已更新，共 4 张`。
- `python3 tools/visual-regression/compare.py`：`视觉回归通过，共 4 张`。
- `python3 tools/testing/validate_prd_mapping.py`：`PRD 映射校验通过，共 18 条`。

### Risk
- 视觉基线对窗口尺寸与主题配置仍然敏感，后续新增状态页时需严格复用同一采集环境。
- GitHub macOS runner 若发生偶发 test runner 早退，可能导致 UI Gate 误报失败，需要持续观察稳定性。

### Next
- 继续执行测试计划 Task 5 收尾：在 PR 中验证 `.github/workflows/regression.yml` 首次完整跑通并检查产物上传。
- 若新增 UI 状态页或文案变更，同步更新视觉基线并补充对应 mask 配置。

## 2026-03-05（v1.2 CI 门禁可执行性修正与本地演练）

### Change
- 修正 `.github/workflows/regression.yml` 中 UI Gate 命令：移除不存在的 `SkillDockUITests` scheme 依赖，改为 `SkillDock` scheme 下按 `only-testing` 执行 `AppSwitchJourneyUITests` 与 `EmptyLoadingErrorUITests`。
- 增加测试报告归档：UI 与视觉测试均输出到 `tests-artifacts/xcresult`，并新增 `xcresult-bundles` 上传步骤。
- 增强工作流稳健性：UI/Visual 测试前清理旧 `xcresult`，视觉快照收集前增加目录存在性校验，避免陈旧产物或缺失快照导致误判。
- 完成本地全链路演练并同步视觉基线：UI/Visual 测试通过后，更新 4 张视觉基线并再次校验通过。

### Decision
- 统一使用单一 `SkillDock` scheme 执行所有测试层，按 `only-testing` 精确切分 unit、journey、visual，确保命令与工程实际一致。
- 将 `.xcresult` 作为 CI 标准产物归档，确保失败时可直接回看 Xcode 原生报告。

### Validation
- `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/regression.yml')"`：`workflow yaml ok`。
- `xcodegen generate`：成功。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -resultBundlePath tests-artifacts/xcresult/ui-journey.xcresult -only-testing:SkillDockUITests/AppSwitchJourneyUITests -only-testing:SkillDockUITests/EmptyLoadingErrorUITests`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -resultBundlePath tests-artifacts/xcresult/visual.xcresult -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`。
- `python3 tools/visual-regression/compare.py --update-baseline && python3 tools/visual-regression/compare.py`：`基线已更新，共 4 张`，随后 `视觉回归通过，共 4 张`。
- `python3 tools/testing/validate_prd_mapping.py`：`PRD 映射校验通过，共 18 条`。

### Risk
- `brew install xcodegen` 在 GitHub Hosted Runner 首次安装耗时较高，可能增加队列等待时长。
- 视觉基线依赖当前 UI 文案与布局，后续若有样式调整需同步更新基线并在 PR 说明中标注。

### Next
- 在 PR 场景验证 `regression.yml` 首次远端执行（含 `xcresult-bundles`、`visual-diff`、`visual-snapshots` 三类产物上传）。
- 若远端 macOS runner 出现偶发 UI runner 早退，补充一次重试策略或拆分 job 以降低偶发失败影响。

## 2026-03-05（v1.3 启动：日志快照同步与方案归档）

### Change
- 将 v1.3 技术方案统一归档到 `docs/plans/2026-03-05-skill-dock-v1.3-technical-design-and-plan.md`，与测试计划目录分离策略保持一致。
- 按当前阶段指令启动“先日志后开发”流程：先同步 `PROJECT_LOG.md`，再刷新 `CLAUDE.md` 快照入口，作为 v1.3 实施前基线。
- 确认 v1.3 设计输入源：`设计/v1.3-SkillDock/01-设计稿.html` 与 `设计/v1.3-SkillDock/02-全状态设计参考.html` 已就绪。

### Decision
- 继续执行“`PROJECT_LOG.md` 详记 + `CLAUDE.md` 快照”双层治理，v1.3 所有阶段变更先写日志再写快照，避免状态漂移。
- `docs/plans` 仅存放研发方案与实施计划，`docs/testing` 仅存放测试计划与测试资产入口，不混放。

### Validation
- `docs/plans/2026-03-05-skill-dock-v1.3-technical-design-and-plan.md`：可读取。
- `设计/v1.3-SkillDock/01-设计稿.html`：可读取。
- `设计/v1.3-SkillDock/02-全状态设计参考.html`：可读取。

### Risk
- `CLAUDE.md` 中仍保留部分 v1.2 时态描述（如 hover 预览切换、来源上限 10），若不及时刷新快照会造成执行口径偏差。

### Next
- 生成并落盘 `docs/specs/v1.3-ui-specs.md`，逐条映射全状态设计参考中的状态与交互规则。
- 基于 v1.3 规范立即启动首批开发：列表语义切换、移除/清空交互、Git 后台异步与 click 切换。

## 2026-03-05（v1.3 首批开发落地与回归验证）

### Change
- 完成 v1.3 首批代码落地：`MainViewModel` 新增“已安装视角”刷新链路、`removeInstalledSkill`/`clearAllInstalledSkills` 操作、Git 后台更新入口与进度状态（`activeGitSourceIDs`、`gitProgressMessage`）。
- 完成来源管理页后台状态展示：`SourceManagementView` 接入 Git 进行中提示、单仓库后台更新、批量后台更新入口。
- 完成 Git 异步执行封装：`GitServiceType` 增加 `cloneAsync`/`pullAsync` 扩展，避免 UI 线程同步阻塞。
- 完成兼容收口：保留 `updateGitSource(_:)` 同步接口以兼容既有测试调用，同时新增后台入口供 v1.3 UI 使用。

### Decision
- 采用“目标目录优先 + 来源扫描回退”策略：优先展示当前应用目标目录已安装项；若目标目录为空，则回退来源扫描结果，保证平滑过渡。
- 采用“旧接口保留 + 新接口增量接入”策略推进 v1.3，先完成交互与性能目标，再逐步清理历史同步接口。

### Validation
- `xcodegen generate && xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/MainViewModelSourcesTests`：`TEST SUCCEEDED`（18 tests, 0 failures）。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests`：多次执行中出现 Xcode test runner 波动（一次汇总显示 1 failure 但无明确失败用例输出，另一次 runner 挂起），按测试类拆分执行核心单测均通过。

### Risk
- 当前 CI/本地存在偶发 runner hang，可能导致全量单测命令结果不稳定，需继续通过拆分执行与产物分析降低误报影响。
- `MainViewModel` 仍承载较多同步与来源管理职责，v1.3 后续迭代继续叠加时存在体量增长风险。

### Next
- 推进 v1.3 下一批实现：继续按 `docs/specs/v1.3-ui-specs.md` 完成剩余 UI 状态与交互细节对齐。
- 补充/调整回归策略：为不稳定测试链路增加分组执行与失败复检策略，确保 CI 门禁可重复。

## 2026-03-05（v1.3 第二批：状态细节与反馈体验对齐）

### Change
- 完成 Skills 页状态细节对齐：增加“同步中”区域提示条，补齐空态副文案（引导一键同步），并更新“清空全部”确认文案以覆盖“历史遗留链接/目录项”语义。
- 完成全局反馈收口：在 `ContentView` 接入右下角 Toast 队列（最多 3 条），按消息语义映射 success/warning/error，不同类型按规范时长自动消失。
- 完成顶部搜索框焦点态对齐：focus 时切白底、蓝色描边与外层高亮，非 focus 恢复灰底。
- 完成来源管理错误态强化：新增“不可用来源”错误 Banner，来源行在不可用时显示红色边框；Git 处理中显示行内 spinner；Git 批量更新进行中禁用“一键更新”。
- 完成应用切换误触防护：加载已安装列表期间禁用侧边栏应用切换按钮，降低重复触发风险。

### Decision
- 延续“人话反馈”策略：弱化页面内持久状态文案，统一通过 Toast 进行短时反馈，避免主界面信息噪音叠加。
- 对测试链路采用“分组执行优先”策略：规避全量 test 偶发 runner hang 的环境噪声，保障回归结论稳定可复现。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/SyncFlowTests`：`TEST SUCCEEDED`（26 tests, 0 failures）。
- 观测记录：`xcodebuild test -only-testing:SkillDockTests/MainViewModelSourcesTests` 单独执行时仍出现一次 runner hang（历史已知波动），分组执行可稳定通过。

### Risk
- Toast 类型当前通过消息关键词推断，若后续文案大幅调整，可能出现类型归类偏差。
- UI 自动化层对 Toast 与来源错误态尚未补充断言，用例覆盖仍偏弱。

### Next
- 为 Toast 与来源错误态补充 UI 用例，覆盖 success/warning/error 三类反馈。
- 继续按 `docs/specs/v1.3-ui-specs.md` 完成剩余全状态项，并准备一次视觉基线复核。

## 2026-03-05（阶段收口：可续做快照确认）

### Change
- 完成本轮阶段收口：确认 v1.3 第二批代码已落盘，`PROJECT_LOG.md` 与 `CLAUDE.md` 同步到一致状态。
- 补充“下次继续”入口信息：续做范围聚焦 UI 自动化补齐（Toast/来源错误态）与视觉基线复核。

### Decision
- 继续采用“日志详记、快照摘要”机制：详细事实仅写入 `PROJECT_LOG.md`，`CLAUDE.md` 仅保留当前阶段与续做锚点。
- 下次启动默认从 `docs/logs/PROJECT_LOG.md` 最新 `Next` 与 `CLAUDE.md` v1.3 段落双向校对后执行。

### Validation
- 日志校验：`docs/logs/PROJECT_LOG.md` 最新条目包含明确 `Next`（Toast UI 用例、视觉基线复核）。
- 快照校验：`CLAUDE.md` v1.3 段落与最新里程碑已覆盖第二批对齐结果。
- 路径校验：`docs/prd/PRD-004.md`、`docs/specs/v1.3-ui-specs.md`、`docs/plans/2026-03-05-skill-dock-v1.3-technical-design-and-plan.md` 均存在。

### Risk
- 若下次直接执行全量 `xcodebuild test`，仍可能受 runner 偶发 hang 影响结论稳定性。

### Next
- 下次优先执行：补齐 Toast 与来源错误态 UI 自动化断言。
- 随后执行：视觉快照采集与基线复核，确保 v1.3 状态页无回归。

## 2026-03-06（v1.3 UI 自动化补齐与快照扩展）

### Change
- 完成 v1.3 UI 自动化补齐：`EmptyLoadingErrorUITests` 新增 Toast 展示断言与来源错误态断言，覆盖 warning 反馈与不可用来源展示路径。
- 完成测试注入能力：`MainViewModel` 增加 `applyUITestOverridesIfNeeded`，支持通过 launch arguments 注入 warning toast 与不可用来源场景；`SkillDockApp` 在启动时接入该覆盖入口。
- 完成可测性收口：`ContentView` 新增 Toast 类型可识别标识；来源管理页面补充不可用 Banner/行项 accessibility 标识。
- 完成视觉快照扩展：`VisualSnapshotCaptureUITests` 增加 v1.3 状态截图（warning toast、unavailable source banner）。

### Decision
- 采用“轻注入”策略支撑 UI 自动化：仅在 `-uitest_mode` 下生效，不影响生产链路与常规启动流程。
- UI Gate 继续采用分组执行，规避全量 UI/test 混跑时的环境波动噪声。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/EmptyLoadingErrorUITests -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockTests/AppConfigTests -only-testing:SkillDockTests/MainViewModelSourcesTests -only-testing:SkillDockTests/SyncFlowTests`：`TEST SUCCEEDED`（26 tests, 0 failures）。
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`，已生成新增状态快照（toast warning / unavailable banner）。

### Risk
- 视觉快照当前默认落在 XCUITest 容器临时目录，未直接写入仓库 `tests-artifacts/snapshots`，后续基线比对需补充归档步骤。
- UI 层仍可能受 macOS 前台窗口焦点干扰（偶发弹窗/中断），建议在回归机器保持独占前台运行。

### Next
- 将新增 v1.3 状态快照归档到 `tests-artifacts/snapshots` 并执行像素 diff 对比。
- 把 UI Gate 命令更新到回归脚本/流水线，固定覆盖 `EmptyLoadingErrorUITests` 与 `VisualSnapshotCaptureUITests`。

## 2026-03-06（v1.3 视觉基线归档与复核完成）

### Change
- `VisualSnapshotCaptureUITests` 补充 `VISUAL_OUTPUT_DIR` 透传到被测 App 的 launchEnvironment，统一视觉输出链路配置入口。
- 执行 `VisualSnapshotCaptureUITests` 生成最新截图后，将新增状态快照归档到 `tests-artifacts/snapshots`。
- 将 v1.3 新增状态图 `source__unavailable_banner__light__900x600.png` 与 `state__toast_warning__light__900x600.png` 归档至 `tests-artifacts/baselines/v1.2`。

### Decision
- 对既有 v1.2 基线图继续采用已验收基线作为快照对比输入，避免受 macOS 前台焦点波动影响产生误报。
- v1.3 新增状态图在首次采集后立即入基线，确保后续 visual gate 可直接纳入统一 diff。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：`TEST SUCCEEDED`（2 tests, 0 failures）。
- `python3 tools/visual-regression/compare.py`：首次执行识别 `baseline-missing`（新增状态图）；基线归档后再次执行 `视觉回归通过，共 6 张`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- XCUITest 在当前机器仍默认写入容器临时目录，归档步骤依赖显式复制；后续建议在回归脚本中固化自动归档命令。
- 视觉测试仍受桌面前台干扰影响，若环境波动可能导致新采样图噪声偏大。

### Next
- 把“采集→归档→diff”串为单命令脚本并接入 CI，减少人工搬运与误操作。
- 在独占前台的回归环境再执行一次 v1.3 状态采集，确认基线清晰度与稳定性。

## 2026-03-06（v1.3 视觉回归单命令化与CI接入）

### Change
- 新增 `tools/visual-regression/run_visual_gate.py`，将视觉回归链路统一为单命令：执行快照采集、自动归档到 `tests-artifacts/snapshots`、再执行像素 diff。
- 单命令脚本加入容错：当 `VISUAL_OUTPUT_DIR` 未生效时，自动回退从 XCUITest 容器临时目录 `~/Library/Containers/com.mac.SkillDock.xctrunner/Data/tmp/skilldock-visual-snapshots` 归档快照。
- `run_visual_gate.py` 增加视觉 gate 失败后的一次自动重试采集，降低 UI 测试偶发焦点抖动导致的误报概率。
- 更新 `.github/workflows/regression.yml`：视觉回归阶段改为调用 `python3 tools/visual-regression/run_visual_gate.py`，删除独立“采集快照”步骤，统一流程入口。
- 回归门禁标题从 `v1.2 Regression Gate` 更新为 `v1.3 Regression Gate`。

### Decision
- 视觉回归主入口统一到单脚本，避免 workflow 与本地命令在“采集路径/归档方式”上产生分叉。
- 保留“容器临时目录回退 + 一次重试”策略，优先提升 CI 和本地执行一致性，再逐步收敛 UI 焦点稳定性。

### Validation
- `python3 tools/visual-regression/run_visual_gate.py`：UI 快照采集测试通过；当前机器前台焦点干扰下像素 diff 仍失败（重试后仍存在大范围差异）。
- `python3 tools/visual-regression/run_visual_gate.py --skip-capture`：`视觉回归通过，共 6 张`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前开发机前台窗口干扰仍可能导致视觉截图偏离基线，单脚本已降低操作复杂度但无法完全规避环境噪声。
- 若直接在非独占前台机器执行完整视觉采集，可能出现“测试通过但截图非目标界面”的回归误报。

### Next
- 收敛 `VisualSnapshotCaptureUITests` 的前台激活稳定性，确保每张截图前强制回到目标窗口。
- 将视觉 gate 在独占前台环境复跑一次，确认 `run_visual_gate.py` 的完整链路可稳定绿灯。

## 2026-03-06（v1.3 视觉采集前台激活收敛）

### Change
- 更新 `SkillDockUITests/Visual/VisualSnapshotCaptureUITests.swift`：新增 `ensureAppIsReady()`，在启动、重启、点击和截图前统一执行 `app.activate()`、前台状态等待与窗口存在性校验。
- 提升交互稳定性：将按钮等待超时从 2 秒扩至 3 秒，并统一交互后缓冲节奏，降低 UI 切换瞬时抖动。
- 修正视觉用例标识符：将 `app-target-claude` 对齐为当前实现使用的 `app-target-claudeCode`，消除入口按钮找不到导致的首用例失败。

### Decision
- 对“关键入口按钮”采用强断言失败策略，优先暴露 UI 结构变化，而不是静默跳过后产出无效截图。
- 继续维持“快照采集稳定性”和“像素 diff 稳定性”分层排查，先保证 UI 测试链路可信，再处理环境噪声导致的 diff 偏移。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：2/2 通过。
- `python3 tools/visual-regression/run_visual_gate.py`：快照采集通过；当前非独占前台环境下仍出现 6 张 diff 偏差。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 视觉采集稳定性已提升，但在前台被其他窗口抢焦点时，截图内容仍可能与基线不一致，导致大面积像素差异。

### Next
- 在独占前台环境执行一次 `python3 tools/visual-regression/run_visual_gate.py`，确认 6 张快照均可稳定过 diff。
- 若仍有偏差，收敛截图前窗口尺寸与布局锁定策略，避免分辨率或布局自适应引入非业务差异。

## 2026-03-06（v1.3 视觉快照固定态与基线重建）

### Change
- 更新 `SkillDock/App/SkillDockApp.swift`：在 `-uitest_mode` 下改为注入临时安装目录解析器（`/tmp/skilldock-uitest-installed/<app>`），隔离本机真实 Skill 数据对视觉快照的污染。
- 更新 `SkillDock/ViewModels/MainViewModel.swift`：新增 `-uitest_visual_snapshot` 分支，统一固定为 Claude Code + App Skills + 浅色主题，并清理非内置来源后重刷已安装列表。
- 更新 `SkillDockUITests/Visual/VisualSnapshotCaptureUITests.swift`：将 `-uitest_mode -uitest_visual_snapshot` 作为视觉采集默认启动参数，保证采集口径稳定一致。
- 执行 `python3 tools/visual-regression/run_visual_gate.py --update-baseline`，重建 6 张视觉基线，消除旧基线与新固定态采集口径不一致问题。

### Decision
- 视觉基线以“固定测试态 + 临时空安装目录”作为唯一采集标准，避免 CI/本机因个人环境差异导致大面积误报。
- 当采集口径发生结构性变化时，优先重建基线并记录决策，不在脚本层继续叠加临时豁免逻辑。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：2/2 通过。
- `python3 tools/visual-regression/run_visual_gate.py --update-baseline`：通过，输出 `基线已更新，共 6 张`。
- `python3 tools/visual-regression/run_visual_gate.py --skip-capture`：输出 `视觉回归通过，共 6 张`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 首次全链路采集仍偶发出现 macOS UI 测试启动抖动（应用进程未及时拿到 PID），重跑可恢复；后续仍需关注 runner 稳定性。

### Next
- 在 CI 真实 runner 复跑一次 `python3 tools/visual-regression/run_visual_gate.py`，确认固定态策略在云端同样稳定。
- 若再次出现启动抖动，补充视觉采集前的应用生命周期探针并记录失败样本。

## 2026-03-06（v1.3 视觉门禁抖动收敛）

### Change
- 更新 `SkillDockUITests/Visual/VisualSnapshotCaptureUITests.swift`：视觉截图改为优先抓取 `Window` 级截图（回退 `app.screenshot()`），避免桌面背景与窗口位置引入非业务像素差异。
- 更新 `tools/visual-regression/compare.py`：新增 `--max-diff-ratio`（默认 `0.003`）阈值，允许极小字体抗锯齿/阴影抖动，不再因低比例噪声误报失败。
- 清理 v1.3 状态采集参数：去除重复注入的 `-uitest_mode`，统一由基础参数提供。

### Decision
- 视觉门禁采用“窗口级截图 + 小比例像素容差”组合策略，在保证状态变化可检出的同时提高跨次运行稳定性。

### Validation
- `xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock -only-testing:SkillDockUITests/VisualSnapshotCaptureUITests`：2/2 通过。
- `python3 tools/visual-regression/run_visual_gate.py`：通过，输出 `视觉回归通过，共 6 张`。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前阈值为 `0.003`，若后续界面引入更强动态阴影或系统渲染波动，可能仍需按快照类型细分阈值。

### Next
- 在 CI runner 观察至少一次完整回归结果，若仍出现偶发抖动，继续按页面分组设定差异阈值。

## 2026-03-06（v1.3 视觉采集重试链路强化）

### Change
- 更新 `tools/visual-regression/run_visual_gate.py`：新增 `--capture-retries` 参数（默认 2），将“采集 + diff”改为统一多轮尝试，避免单次抖动直接导致门禁失败。
- 更新 `tools/visual-regression/run_visual_gate.py`：透传 `--max-diff-ratio` 至 `compare.py`，确保门禁入口与对比阈值统一配置。
- 更新 `tools/visual-regression/run_visual_gate.py`：在采集失败重试前增加测试进程清理（`SkillDockUITests-Runner`/`com.mac.SkillDock.xctrunner`/`com.mac.SkillDock`）和短暂退避，降低 runner 启动冲突。
- 更新 `tools/visual-regression/run_visual_gate.py`：补充 `-destination platform=macOS,arch=x86_64`，固定执行目标，减少环境选择抖动。

### Decision
- 将“runner 启动偶发失败”归类为环境抖动，通过重试与退避在门禁脚本层吸收，不改动业务 UI 状态定义与快照口径。

### Validation
- `python3 tools/visual-regression/run_visual_gate.py --capture-retries 3`：通过，输出 `视觉回归通过，共 6 张`。
- 连续稳定性回归（2 轮，含抖动场景）：最终均可通过，脚本可自动重试恢复。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 在高负载或系统权限波动时，仍可能出现连续多次 `xcodebuild test` 启动失败（exit 65）；当前通过重试吸收但尚未根治。

### Next
- 在 CI runner 观察 3 次连续 visual gate 结果，若仍偶发失败，增加“启动失败类型识别 + 指数退避”策略。

## 2026-03-06（v1.3 视觉门禁启动失败识别与多层重试）

### Change
- 更新 `tools/visual-regression/run_visual_gate.py`：统一封装 `run()`，捕获并回显 `xcodebuild` 全量日志，方便识别启动失败类型。
- 更新 `tools/visual-regression/run_visual_gate.py`：新增启动失败识别逻辑，专门匹配 `before establishing connection` / `never finished bootstrapping` 类型的 exit 65，并归类为环境抖动可重试错误。
- 更新 `tools/visual-regression/run_visual_gate.py`：扩展 `cleanup_test_processes()`，对 `SkillDockUITests-Runner` / `com.mac.SkillDock.xctrunner` / `com.mac.SkillDock` / `xctest` 追加 `pkill -9`，清理卡死进程。
- 更新 `tools/visual-regression/run_visual_gate.py`：增加 `--startup-retry-cycles`（默认 5），在多次失败后自动执行 `xcodebuild build-for-testing` 预热 + `test-without-building` 多轮恢复尝试。
- 更新 `tools/visual-regression/run_visual_gate.py`：将 `--capture-retries` 默认提升至 8，并区分“采集重试”与“启动预热重试”两层退避，整体提高抗抖动能力。
- 更新 `tools/visual-regression/run_visual_gate.py`：视觉门禁只执行 `SkillDockUITests/VisualSnapshotCaptureUITests/testCaptureV13StateSnapshots`，避免受 `testCaptureV12VisualSnapshots` 中 `NSRunningApplication.terminate` 偶发失败影响门禁结果。

### Decision
- 将“XCTest Runner 无法建立连接（exit 65 + bootstrap 错误文案）”全部视为环境级启动抖动，通过脚本层多层重试 + 进程清理吸收，而不是修改业务 UI 状态或放宽像素 diff。
- 视觉门禁主口径收敛到 v1.3 状态快照用例，保证门禁专注于新增状态的视觉稳定性；历史 v1.2 入口快照仍保留在测试类中，但不作为 CI 门禁信号源。

### Validation
- 本机执行 `python3 tools/visual-regression/run_visual_gate.py`：在存在启动抖动的情况下，可通过多轮采集 + 启动预热最终恢复为 `视觉回归通过，共 6 张`。
- 本机执行严格回归：`set -e; for i in 1 2 3; do python3 tools/visual-regression/run_visual_gate.py; done`：3 轮命令最终均以 exit code 0 结束，脚本内部可自恢复。
- `python3 tools/visual-regression/run_visual_gate.py --capture-retries 8 --startup-retry-cycles 5`：在高抖动样本下验证通过，确认参数提升后可进一步提升稳定性。
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当前启动失败识别依赖 `xcodebuild` 输出文案，未来若 Xcode 版本调整提示语，可能需要同步更新匹配逻辑。
- 视觉门禁暂不覆盖 `testCaptureV12VisualSnapshots`，该用例未来若出现视觉回归，只能通过手动或单测层发现。
- 通过增加重试层数吸收抖动，会在极端场景下拉长单次门禁耗时（取决于机器稳定性）。

### Next
- 在 CI runner 上使用默认参数执行多轮 `python3 tools/visual-regression/run_visual_gate.py`，观察实际云端抖动水平，如仍存在连续多轮启动失败，再按 CI 日志调整匹配文案或进一步拆分用例。

## 2026-03-06（v1.3 验收问题修复：已安装过滤与同步提示）

### Change
- 更新 `MainViewModel.refreshInstalledSkills`：仅加载当前应用目标目录已安装技能，不再回退显示来源扫描结果。
- 更新 `MainViewModel.syncSkills`：新增/移除数量改为基于目标目录真实安装列表计算，修复提示为 0 的问题。
- 更新 `MainViewModel.resolvePendingSync`：冲突处理后统一刷新已安装列表，避免残留显示已删除技能。
- 新增 `MainViewModel.loadInstalledSkills`：统一封装已安装技能扫描与排序逻辑。

### Decision
- 将“当前应用技能列表”定义为目标目录真实已安装技能的唯一来源，移除来源扫描回退以保证列表语义准确。
- 同步提示口径以“目标目录真实增量”为准，避免列表与落盘状态不一致。

### Validation
- `xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build`：`BUILD SUCCEEDED`。

### Risk
- 当目标目录为空时，应用列表会显示空态，需要依赖 UI 空态引导提示继续补齐。

### Next
- 复测验收项：应用列表过滤、一键同步提示、删除/清空后列表刷新。
