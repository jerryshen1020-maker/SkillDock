# SkillDock

SkillDock 是一款 macOS 应用，用于统一管理多应用的 AI skills。支持本地目录与 Git 来源、一键同步、全局开关与状态反馈。

## 主要功能

- 多应用技能目录管理（Claude Code / Codex / OpenCode / Trae / Trae CN）
- 本地来源与 Git 来源管理
- 一键同步与冲突处理
- 技能搜索与详情查看
- 全局启用/禁用与状态反馈

## 下载安装

1. 在 GitHub Releases 下载最新版本
2. 解压并将 SkillDock.app 拖入「应用程序」
3. 双击打开即可使用

如果首次打开被系统拦截，请到「系统设置 → 隐私与安全性」允许打开。

## 使用方式

1. 进入「来源管理」添加本地目录或 Git 仓库
2. 切换左侧应用，点击「一键同步」写入对应应用的 skills 目录
3. 在列表中搜索、查看详情或移除/清空

## 支持的应用与默认目录

- Claude Code: `~/.claude/skills`
- Codex: `~/.codex/skills`
- OpenCode: `~/.config/opencode/skills`
- Trae: `~/.trae/skills`
- Trae CN: `~/.trae-cn/skills`

## 开发与构建

本项目使用 XcodeGen 生成项目文件。

```bash
xcodegen generate
xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build
```

运行测试：

```bash
xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock
```

## 常见问题

**Q: 添加来源后列表为空？**  
请确认来源目录内包含 `SKILL.md`，且目录未被系统隐藏。

**Q: 同步后应用未生效？**  
请确认目标应用的 skills 目录存在，且当前用户对该目录有读写权限。

